namespace :db do
  desc "Refresh materialized views for dashboards"
  task refresh_materialized_views: :environment do
    RefreshMaterializedViews.call
  end

  desc "Generate fake Patient data"
  task seed_patients: :environment do
    abort "Can't run this task in env:#{ENV["SIMPLE_SERVER_ENV"]}!" if ENV["SIMPLE_SERVER_ENV"] == "production"
    Seed::Runner.new.call
  end

  desc "Clear patient data, regenerate patient seed data, and refresh materialized views"
  task purge_and_refresh: [:purge_users_data, :seed_patients, :refresh_materialized_views]

  desc "Generate some fake data for a seed user roles"
  task seed_users_data: :environment do
    abort "Can't run this task in env:#{ENV["SIMPLE_SERVER_ENV"]}!" if ENV["SIMPLE_SERVER_ENV"] == "production"

    if ENV["SEED_GENERATED_ACTIVE_USER_ROLE"].blank? || ENV["SEED_GENERATED_INACTIVE_USER_ROLE"].blank?
      abort "Can't proceed! \n" \
      "Set configs for: ENV['SEED_GENERATED_ACTIVE_USER_ROLE'] and ENV['SEED_GENERATED_INACTIVE_USER_ROLE'] " \
      "before running this task. \n" \
      "Make sure there are some users created with those two roles; see db:seed."
    end

    User.where(role: [ENV["SEED_GENERATED_ACTIVE_USER_ROLE"], ENV["SEED_GENERATED_INACTIVE_USER_ROLE"]]).each do |user|
      if Rails.env.development?
        puts "Synchronous"
        SeedUsersDataJob.new.perform(user.id)
      else
        SeedUsersDataJob.perform_async(user.id)
      end
    end
  end

  desc "Purge all Patient data"
  task purge_users_data: :environment do
    abort "Can't run this task in #{ENV["SIMPLE_SERVER_ENV"]}!'" if ENV["SIMPLE_SERVER_ENV"] == "production"

    require "tasks/scripts/purge_users_data"
    PurgeUsersData.perform
  end
end
