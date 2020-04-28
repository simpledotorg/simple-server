namespace :purge do
  require 'tasks/scripts/purge_users_data'

  desc 'Purge all user data; Example: rake "purge:users_data'
  task users_data: :environment do
    PurgeUsersData.perform
  end
end
