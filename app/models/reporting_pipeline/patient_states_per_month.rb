module ReportingPipeline
  class PatientStatesPerMonth < Matview
    self.table_name = "reporting_patient_states_per_month"
    belongs_to :patient
  end
end
