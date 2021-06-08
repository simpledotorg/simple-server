class ReportingPatientStatesPerMonth < ActiveRecord::Base
  self.table_name = "reporting_patient_states_per_month"
  belongs_to :patient
  belongs_to :assigned_facility, class_name: "Facility", foreign_key: :patient_assigned_facility_id

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, cascade: false)
  end
end
