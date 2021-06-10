module Reporting
  class ReportingPatientStatesPerMonth < ActiveRecord::Base
    self.table_name = "reporting_patient_states_per_month"
    belongs_to :patient, foreign_key: :id

    def self.refresh
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Period::REPORTING_TIME_ZONE}'")
        # TODO: concurrent refreshes need a unique index
        Scenic.database.refresh_materialized_view("reporting_facilities", concurrently: false, cascade: false)
        Scenic.database.refresh_materialized_view("reporting_patient_blood_pressures_per_month", concurrently: false, cascade: false)
        Scenic.database.refresh_materialized_view("reporting_patient_visits_per_month", concurrently: false, cascade: false)
        Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
      end
    end
  end
end
