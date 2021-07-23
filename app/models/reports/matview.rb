module Reports
  class Matview < ActiveRecord::Base
    def self.refresh
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
        Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
      end
    end
  end
end
