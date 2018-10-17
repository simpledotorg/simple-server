namespace :data_migration do
  desc "Update sync_approval_status for existing users to `approved`"
  task update_sync_approval_status_for_existing_users: :environment do
    now = Time.now
    users = User.where(sync_approval_status: nil).where("created_at <= ?", now)
    puts "Updating approval status for #{users.count} users"

    users.update(sync_approval_status: User.sync_approval_statuses[:allowed])

    puts "Updated sync approval status to approved for users created before #{now}"
  end

  desc "Populate user facilities table from users table"
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
end
