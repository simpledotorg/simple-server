namespace :data_migration do
  desc "Associate all facility groups in an organization's to a protocol"
  task :associate_protocol_to_organization_facility_groups, [:organization_id, :protocol_id] => :environment do |_t, args|
    organization = Organization.find(args.organization_id)
    protocol = Protocol.find(args.protocol_id)
    puts "Associating organization #{organization.name} to protocol #{protocol.name}"
    puts "Associating protocol for #{organization.facility_groups.count} facility groups"
    organization.facility_groups.update(protocol: protocol)
  end

  desc "Update 'appointment_type' for existing appointments to 'manual'"
  task set_appointment_type_to_manual_for_existing_appointments: :environment do
    appointments = Appointment.where(appointment_type: nil)

    number_of_appointments_marked_manual = 0
    appointments.each do |app|
      puts "Marking appointment #{app.id} as 'manual'"
      app.update_column(:appointment_type, Appointment.appointment_types[:manual])
      number_of_appointments_marked_manual += 1
    end

    puts "Total number of appointments marked as 'manual' = #{number_of_appointments_marked_manual}"
  end

  desc "Create automatic appointment for defaulters so that they show up in the Overdue List"
  task create_automatic_appointment_for_defaulters: :environment do
    last_bp_older_than_one_month = ->(p) { p.latest_blood_pressure.blank? || p.latest_blood_pressure.device_created_at < 1.month.ago }

    patient_is_hypertensive = ->(p) { p.latest_blood_pressure.present? && p.latest_blood_pressure.hypertensive? }

    patient_has_cardio_vascular_history = ->(p) { p.medical_history.present? && p.medical_history.indicates_risk? }

    defaulters = Patient.select do |p|
      p.appointments.count == 0 &&
        last_bp_older_than_one_month.call(p) &&
        (patient_is_hypertensive.call(p) || patient_has_cardio_vascular_history.call(p) || p.prescription_drugs.present?)
    end

    puts "Found #{defaulters.count} defaulters"

    if defaulters.blank? || defaulters.empty?
      abort("No defaulters found. Aborting task.")
    end

    puts "Processing #{defaulters.count} defaulters..."

    processed_defaulters_count = 0
    unprocessed_or_errored_defaulters_count = 0

    defaulters.each do |defaulter|
      if defaulter.latest_blood_pressure.blank?
        puts "Failed to find latest Blood Pressure reading for defaulter #{defaulter.id}. Skipping patient..."
        unprocessed_or_errored_defaulters_count += 1
        next
      end

      latest_bp_facility_id = defaulter.latest_blood_pressure.facility_id
      appointment_creation_time = defaulter.latest_blood_pressure.device_created_at
      appointment_scheduled_date = appointment_creation_time + 1.month

      begin
        automatic_appointment =
          Appointment.create(patient_id: defaulter.id, facility_id: latest_bp_facility_id,
                             device_created_at: appointment_creation_time, device_updated_at: appointment_creation_time, status: 'scheduled', scheduled_date: appointment_scheduled_date, appointment_type: Appointment.appointment_types[:automatic])

        if automatic_appointment.errors.present?
          puts "Error(s) while creating automatic appointment for patient #{defaulter.id}: #{automatic_appointment.errors.messages}"
          unprocessed_or_errored_defaulters_count += 1
          next
        end

        processed_defaulters_count += 1

        puts "Created automatic appointment #{automatic_appointment.id} for defaulter #{defaulter.id}"
      rescue StandardError => err
        puts "Failed to create automatic appointment for defaulter #{defaulter.id}. Reason: #{err}"
        unprocessed_or_errored_defaulters_count += 1
      end
    end

    puts "Number of defaulters processed (automatic appointment created) = #{processed_defaulters_count}"
    puts "Number of unprocessed/errored defaulters = #{unprocessed_or_errored_defaulters_count}"
  end

  desc "Set default 'recorded_at' for existing blood pressure and patient records"
  task set_default_recorded_at_for_existing_blood_pressures: :environment do
    # For BloodPressure records,
    # we default to the device_created_at
    puts 'Fetching BloodPressure where recorded_at is nil...'
    blood_pressures = BloodPressure.where(recorded_at: nil)

    puts "Total number of BloodPressure records to be updated = #{blood_pressures.size}"

    puts 'Updating BloodPressure recorded_at to be device_created_at...'
    blood_pressures.update_all('recorded_at = device_created_at')

    # Patients' recorded_at is set to their earliest BP's device_created_at if older
    puts 'Fetching Patients where recorded_at is nil'
    patients =
      Patient.select(%Q(
      DISTINCT ON(patients.id) patients.id,
patients.device_created_at AS patient_registration_date,
blood_pressures.recorded_at AS oldest_bp_recorded_at))
        .left_joins(:blood_pressures)
        .order('patients.id', 'blood_pressures.recorded_at')
        .where('patients.recorded_at IS NULL')

    puts 'Updating Patients recorded_at...'
    patients.each do |patient|
      patient_recorded_at = patient.oldest_bp_recorded_at.present? ?
                              [patient.oldest_bp_recorded_at, patient.patient_registration_date].min :
                              patient.patient_registration_date
      Patient.where(id: patient.id).update_all(recorded_at: patient_recorded_at)
    end

    puts "Total number of Patient records updated = #{patients.size}"
  end

  desc "Create master users for users"
  task create_master_users_for_users: :environment do
    OldUser.where.not(sync_approval_status: nil).all.each do |user|
      next if User.find_by(id: user.id).present?
      user.transaction do
        user_attributes = user.attributes.with_indifferent_access
        master_user = User.create(user_attributes.slice(
          :id,
          :full_name,
          :sync_approval_status,
          :sync_approval_status_reason,
          :device_created_at,
          :device_updated_at,
          :created_at,
          :updated_at,
          :deleted_at
        ))

        phone_number_authentication = PhoneNumberAuthentication.create(user_attributes.slice(
          :phone_number,
          :password_digest,
          :otp,
          :otp_valid_until,
          :registration_facility_id,
          :logged_in_at,
          :access_token,
          :created_at,
          :updated_at,
          :deleted_at
        ))

        master_user.user_authentications.create(
          authenticatable: phone_number_authentication
        )
      end
    end
  end

  desc "Create master users for admins"
  task create_master_users_for_admins: :environment do
    require 'tasks/scripts/create_master_user'

    Admin.all.each do |admin|
      begin
        CreateMasterUser.from_admin(admin)
      rescue StandardError => e
        puts "Skipping #{admin.email}: #{e.message}"
      end
    end
  end

  desc "Fix null invited_by for email authentications when migrating from admins"
  task fix_invited_by_for_email_authentications: :environment do
    EmailAuthentication.all.each do |email_authentication|
      email_authentication.transaction do
        admin = Admin.find_by(email: email_authentication.email)
        invited_by = EmailAuthentication.find_by(email: admin.invited_by.email)

        email_authentication.invited_by = invited_by.master_user
        email_authentication.save
      end
    end
  end

  desc 'Move all the user phone numbers from the call logs to a de-normalized caller_phone_number field'
  task de_normalize_user_phone_numbers_in_call_logs: :environment do
    CallLog.all.each do |call_log|
      call_log.caller_phone_number = call_log.user.phone_number
      call_log.save!
    end
  end
end
