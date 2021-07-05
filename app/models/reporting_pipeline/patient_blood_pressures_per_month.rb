module ReportingPipeline
  class PatientBloodPressuresPerMonth < Matview
    self.table_name = "reporting_patient_blood_pressures_per_month"
    belongs_to :patient
  end
end
