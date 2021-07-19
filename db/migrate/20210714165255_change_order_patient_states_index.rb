class ChangeOrderPatientStatesIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :reporting_patient_states, name: "patient_states_patient_id_month_date"
    add_index :reporting_patient_states, [:month_date, :patient_id], unique: true, name: "patient_states_month_date_patient_id"
  end
end
