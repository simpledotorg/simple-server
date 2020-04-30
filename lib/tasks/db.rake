namespace :db do
  desc 'Generate some fake data for a seed user roles;Example: rake "db:seed_user_data'
  task seed_user_data: :environment do
    abort "Can't run this task in env:#{ENV['SIMPLE_SERVER_ENV']}!" if ENV['SIMPLE_SERVER_ENV'] == 'production'

    if ENV['ACTIVE_GENERATED_USER_ROLE'].blank? || ENV['INACTIVE_GENERATED_USER_ROLE'].blank?
      abort "Can't proceed! \n" \
      "Set configs for: ENV['ACTIVE_GENERATED_USER_ROLE'] and ENV['INACTIVE_GENERATED_USER_ROLE'] " \
      "before running this task. \n" \
      "Make sure there are some users created with those two roles; see db:seed."
    end


    User.where(role: [ENV['ACTIVE_GENERATED_USER_ROLE'], ENV['INACTIVE_GENERATED_USER_ROLE']])
      .each { |user| SeedUserDataJob.perform_async(user.id) }
  end

  desc 'Purge all user data; Example: rake "db:purge_user_data'
  task purge_user_data: :environment do
    abort "Can't run this task in #{ENV['SIMPLE_SERVER_ENV']}!'" if ENV['SIMPLE_SERVER_ENV'] == 'production'

    require 'tasks/scripts/purge_users_data'
    PurgeUsersData.perform
  end
end
