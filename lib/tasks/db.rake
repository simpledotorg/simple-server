namespace :db do
  desc "Refresh reporting views for dashboards"
  task refresh_reporting_views: :environment do
    RefreshReportingViews.call
    puts "Reporting views have been refreshed"
  end

  task refresh_matviews: :refresh_reporting_views

  desc "Generate fake Patient data"
  task seed_patients: :environment do
    abort "Can't run this task in env:#{ENV["SIMPLE_SERVER_ENV"]}!" if ENV["SIMPLE_SERVER_ENV"] == "production"
    Seed::Runner.new.call
  end

  desc "Clear patient data, regenerate patient seed data, and refresh reporting views"
  task purge_and_reseed: [:purge_users_data, :seed_patients, :refresh_reporting_views]

  desc "Purge all Patient data and refresh reporting views"
  task purge_users_data: :environment do
    abort "Can't run this task in #{ENV["SIMPLE_SERVER_ENV"]}!'" if ENV["SIMPLE_SERVER_ENV"] == "production"

    require "tasks/scripts/purge_users_data"
    PurgeUsersData.perform

    RefreshReportingViews.call
  end

  namespace :structure do
    desc "Clean structure.sql - commenting out COMMENT ON EXTENSION"
    task :clean do
      structure = IO.read("db/structure.sql")
      structure.gsub!(/^(COMMENT ON EXTENSION)/, '-- \1')
      File.write("db/structure.sql", structure)
    end
  end
end

Rake::Task["db:structure:dump"].enhance do
  Rake::Task["db:structure:clean"].invoke
end

Rake::Task["db:seed"].enhance do
  ENV["REFRESH_MATVIEWS_CONCURRENTLY"] = "false"
  Rake::Task["db:refresh_reporting_views"].invoke
end
