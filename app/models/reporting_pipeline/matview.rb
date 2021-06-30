module ReportingPipeline
  class Matview < ActiveRecord::Base
    def self.refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
    end
  end
end
