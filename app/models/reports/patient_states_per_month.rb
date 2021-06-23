module Reports
  class PatientStatesPerMonth < ActiveRecord::Base
    def self.refresh
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
        Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: true)
      end
    end

    self.table_name = "reporting_patient_states_per_month"
  end
end
