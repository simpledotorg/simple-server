namespace :data_migration do
  desc "Update sync_approval_status for existing users to `approved`"
  task update_sync_approval_status_for_existing_users: :environment do
    now = Time.now
    users = User.where(sync_approval_status: nil).where("created_at <= ?", now)
    puts "Updating approval status for #{users.count} users"

    users.update(sync_approval_status: User.sync_approval_statuses[:allowed])

    puts "Updated sync approval status to approved for users created before #{now}"
  end
end