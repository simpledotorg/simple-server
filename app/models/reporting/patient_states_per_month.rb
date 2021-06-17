module Reporting
  class PatientStatesPerMonth < ReportingMatview
    self.table_name = "reporting_patient_states_per_month"
    belongs_to :patient, foreign_key: :id
  end
end
