namespace :data_migration do
  desc 'Update sync_approval_status for existing users to `approved`'
  task update_sync_approval_status_for_existing_users: :environment do
    now = Time.now
    users = User.where(sync_approval_status: nil).where('created_at <= ?', now)
    puts "Updating approval status for #{users.count} users"

    users.update(sync_approval_status: User.sync_approval_statuses[:allowed])

    puts "Updated sync approval status to approved for users created before #{now}"
  end

  desc 'Populate user facilities table from users table'
  task create_user_facility_records_for_users: :environment do
    ActiveRecord::Base.transaction do
      users = User.all
      puts "Creating UserFacility records fors #{users.count} users"
      users.each do |user|
        UserFacility.create(user_id: user.id, facility_id: user.facility.id)
      end
      puts "Created UserFacility records fors #{users.count} users"
    end
  end

  desc "Populate initial registration facility and user for patients"
  task update_initial_registration_for_patients: :environment do
    ActiveRecord::Base.transaction do
      patients = Patient.all
      puts "Updating initial registration associations for #{patients.count} patients"

      patients.each do |patient|
        if first_bp = patient.blood_pressures.order(:device_created_at).first
          patient.update(registration_facility: first_bp.facility, registration_user: first_bp.user)
        end
      end

      puts "Updated initial registration associations for #{patients.count} patients"
    end
  end

  desc 'Populate questions in medical histories from deprecated boolean fields'
  task populate_medical_history_records_from_boolean_fields: :environment do
    MedicalHistory.all.each do |record|
      MedicalHistory::MEDICAL_HISTORY_QUESTIONS.each do |question|
        boolean_value = record.read_attribute(question.to_s + '_boolean')
        enum_value = Api::V1::MedicalHistoryTransformer::INVERTED_MEDICAL_HISTORY_ANSWERS_MAP[boolean_value] || :unknown
        record.write_attribute(question, enum_value)
      end
      record.save
    end
  end

  desc 'Create IHMI Organization and facility groups for Punjab facilities'
  task organize_punjab_facilities: :environment do
    ihmi = Organization.find_or_create_by(name: 'India Hypertension Management Initiative')
    facility_group = ihmi.facility_groups.find_or_create_by(name: 'All IHMI Facilities')
    punjab_facilities = Facility.where(state: 'Punjab', facility_group: nil)
    punjab_facilities.update_all(facility_group_id: facility_group.id)
  end

  desc 'Add registration facility to existing users from user facility'
  task populate_registration_facility_for_users: :environment do
    User.where(facility: nil).each do |user|
      user_facility = UserFacility.where(user: user).limit(1).first
      if user_facility.present?
        puts "Adding #{user_facility.facility.name} as the registration facility for user #{user.full_name}"
        user.update(facility: user_facility.facility)
      else
        puts "Did not find user facility for user #{user.full_name}"
      end
    end
  end

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
    appointments = Appointment.all.select { |app| app.appointment_type.blank? }

    number_of_appointments_marked_manual = 0
    appointments.each do |app|
      puts "Marking appointment #{app.id} as 'manual'"
      app.appointment_type = Appointment.appointment_types[:manual]
      app.save
      number_of_appointments_marked_manual += 1
    end

    puts "Total number of appointments marked as 'manual' = #{number_of_appointments_marked_manual}"
  end

  desc "Create automatic appointment for defaulters so that they show up in the Overdue List"
  task create_automatic_appointment_for_defaulters: :environment do
    last_bp_older_than_one_month = ->(p) { p.latest_blood_pressure.blank? || p.latest_blood_pressure.device_created_at < 1.month.ago }

    patient_is_hypertensive = ->(p) { p.latest_blood_pressure.present? && (p.latest_blood_pressure.systolic > 140 || p.latest_blood_pressure.diastolic < 90) }

    patient_has_medical_history = ->(p) { (p.medical_history.present? && (p.medical_history.prior_stroke == "yes" || p.medical_history.prior_heart_attack == "yes" || p.medical_history.chronic_kidney_disease == "yes" ||
      p.medical_history.diabetes == "yes")) }

    defaulters = Patient.select do |p|
      p.appointments.count == 0 &&
        last_bp_older_than_one_month.call(p) &&
        (patient_is_hypertensive.call(p) || patient_has_medical_history.call(p) || p.prescription_drugs.present?)
    end

    puts "Found #{defaulters.count} defaulters"

    if defaulters.blank? || defaulters.empty?
      puts "No defaulters found. Aborting task."
      return
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
      app_creation_time = Time.now
      app_scheduled_date = 32.days.ago # to trigger overdue-ness

      begin
        automatic_appointment =
          Appointment.create(patient_id: defaulter.id, facility_id: latest_bp_facility_id,
                             device_created_at: app_creation_time, device_updated_at: app_creation_time, created_at: app_creation_time, updated_at: app_creation_time,
                             scheduled_date: app_scheduled_date, appointment_type: Appointment.appointment_types[:automatic])

        automatic_appointment.save
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
end
