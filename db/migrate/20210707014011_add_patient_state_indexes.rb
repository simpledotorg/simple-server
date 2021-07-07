class AddPatientStateIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :reporting_monthly_patient_states, [:assigned_facility_region_id], name: "patient_states_assigned_facility"
    add_index :reporting_monthly_patient_states, [:assigned_block_region_id], name: "patient_states_assigned_block"
    add_index :reporting_monthly_patient_states, [:assigned_district_region_id], name: "patient_states_assigned_district"
    add_index :reporting_monthly_patient_states, [:assigned_state_region_id], name: "patient_states_assigned_state"
    add_index :reporting_monthly_patient_states, [:patient_id, :month_date], unique: true, name: "patient_states_patient_id_month_date"
    add_index :reporting_monthly_patient_states, [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
  end
end
