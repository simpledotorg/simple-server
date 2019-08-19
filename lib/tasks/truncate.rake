namespace :db do
  desc "Truncate all tables"
  task :truncate => :environment do
    conn = ActiveRecord::Base.connection
    tables = conn.execute("
      SELECT tablename
      FROM pg_catalog.pg_tables
      WHERE schemaname = 'public' AND
            tablename NOT IN ('schema_migrations', 'ar_internal_metadata')
    ")

    tables.each do |t|
      tablename = t["tablename"]
      conn.execute("TRUNCATE #{tablename} CASCADE")
    end
  end
end