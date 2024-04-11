class AddGenderAndAgeIndexToReportingPatientStates < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_patient_states, :gender
    add_index :reporting_patient_states, :age
    add_index :reporting_patient_states, [:gender, :age]
  end
end
