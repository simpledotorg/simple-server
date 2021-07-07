module ReportingPipeline
  class MonthlyPatientState < Matview
    self.table_name = "reporting_monthly_patient_states"
    belongs_to :patient
  end
end
