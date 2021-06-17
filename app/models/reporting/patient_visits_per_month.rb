module Reporting
  class PatientVisitsPerMonth < ReportingMatview
    self.table_name = "reporting_patient_visits_per_month"
    belongs_to :patient
  end
end
