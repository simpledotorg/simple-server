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
end
