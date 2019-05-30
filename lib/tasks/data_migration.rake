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

  desc "Create master users for users"
  task create_master_users_for_users: :environment do
    User.all.each do |user|
      next if MasterUser.find_by(id: user.id).present?
      user.transaction do
        user_attributes = user.attributes.with_indifferent_access
        master_user = MasterUser.create(user_attributes.slice(
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
          :logged_in_at,
          :access_token,
          :created_at,
          :updated_at,
          :deleted_at
        ))

        master_user.master_user_authentications.create(
          authenticatable: phone_number_authentication
        )
      end
    end
  end

  desc "Create master users for admins"
  task create_master_users_for_admins: :environment do
    Admin.all.each do |admin|
      master_user_id = UUIDTools::UUID.md5_create(
        UUIDTools::UUID_DNS_NAMESPACE,
        { email: admin.email }.to_s
      ).to_s

      master_user_full_name = admin.email.split('@').first

      next if MasterUser.find_by(id: master_user_id).present?
      admin.transaction do
        admin_attributes = admin.attributes.with_indifferent_access

        master_user = MasterUser.create(
          id: master_user_id,
          full_name: master_user_full_name,
          sync_approval_status: 'denied',
          sync_approval_status_reason: 'User is an admin',
          device_created_at: admin.created_at,
          device_updated_at: admin.updated_at,
          created_at: admin.created_at,
          updated_at: admin.updated_at,
          deleted_at: admin.deleted_at,
        )

        email_authentication = EmailAuthentication.new(admin_attributes.except(:id, :role))

        email_authentication.save(validate: false)

        master_user.master_user_authentications.create(
          authenticatable: email_authentication
        )
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
  task de_normalize_user_phone_numbers_in_call_logs: :environment  do
    CallLog.all.each do |call_log|
      call_log.caller_phone_number = call_log.user.phone_number
      call_log.save!
    end
  end
end
