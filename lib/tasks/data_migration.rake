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
end