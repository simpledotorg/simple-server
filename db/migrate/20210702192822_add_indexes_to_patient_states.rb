class AddIndexesToPatientStates < ActiveRecord::Migration[5.2]
  def change
    add_index :reporting_patient_states_per_month, [:assigned_facility_region_id], name: "patient_states_assigned_facility"
    add_index :reporting_patient_states_per_month, [:assigned_block_region_id], name: "patient_states_assigned_block"
    add_index :reporting_patient_states_per_month, [:assigned_district_region_id], name: "patient_states_assigned_district"
    add_index :reporting_patient_states_per_month, [:assigned_state_region_id], name: "patient_states_assigned_state"
    add_index :reporting_patient_states_per_month, [:assigned_organization_region_id], name: "patient_organization_assigned_state"
    add_index :reporting_patient_states_per_month, [:month_date], name: "patient_states_month_date"
    add_index :reporting_patient_states_per_month, [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
  end
end
