module Reports
  class PatientState < Matview
    self.table_name = "reporting_patient_states"
    belongs_to :patient
  end
end
