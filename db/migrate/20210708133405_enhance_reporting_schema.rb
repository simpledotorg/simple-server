class EnhanceReportingSchema < ActiveRecord::Migration[5.2]
  def up
    drop_view :reporting_patient_states, materialized: true
    drop_view :reporting_patient_visits, materialized: true
    drop_view :reporting_patient_blood_pressures, materialized: true
    drop_view :reporting_facilities, materialized: false
    drop_view :reporting_months, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_months, version: 2, materialized: false
    create_view :reporting_facilities, version: 2, materialized: false
    create_view :reporting_patient_blood_pressures, version: 2, materialized: true
    create_view :reporting_patient_visits, version: 2, materialized: true
    create_view :reporting_patient_states, version: 2, materialized: true

    add_index :reporting_patient_states, [:assigned_facility_region_id], name: "patient_states_assigned_facility"
    add_index :reporting_patient_states, [:assigned_block_region_id], name: "patient_states_assigned_block"
    add_index :reporting_patient_states, [:assigned_district_region_id], name: "patient_states_assigned_district"
    add_index :reporting_patient_states, [:assigned_state_region_id], name: "patient_states_assigned_state"
    add_index :reporting_patient_states, [:patient_id, :month_date], unique: true, name: "patient_states_patient_id_month_date"
    add_index :reporting_patient_states, [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
  end

  def down
    drop_view :reporting_patient_states, materialized: true
    drop_view :reporting_patient_visits, materialized: true
    drop_view :reporting_patient_blood_pressures, materialized: true
    drop_view :reporting_facilities, materialized: false
    drop_view :reporting_months, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_months, version: 1, materialized: false
    create_view :reporting_facilities, version: 1, materialized: false
    create_view :reporting_patient_blood_pressures, version: 1, materialized: true
    create_view :reporting_patient_visits, version: 1, materialized: true
    create_view :reporting_patient_states, version: 1, materialized: true

    add_index :reporting_patient_states, [:assigned_facility_region_id], name: "patient_states_assigned_facility"
    add_index :reporting_patient_states, [:assigned_block_region_id], name: "patient_states_assigned_block"
    add_index :reporting_patient_states, [:assigned_district_region_id], name: "patient_states_assigned_district"
    add_index :reporting_patient_states, [:assigned_state_region_id], name: "patient_states_assigned_state"
    add_index :reporting_patient_states, [:patient_id, :month_date], unique: true, name: "patient_states_patient_id_month_date"
    add_index :reporting_patient_states, [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
  end
end
