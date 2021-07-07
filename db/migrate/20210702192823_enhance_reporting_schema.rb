class EnhanceReportingSchema < ActiveRecord::Migration[5.2]
  def up
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: false
    drop_view :reporting_months, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_months, version: 2, materialized: false
    create_view :reporting_facilities, version: 2, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, version: 2, materialized: true
    create_view :reporting_patient_visits_per_month, version: 3, materialized: true
    create_view :reporting_patient_states_per_month, version: 3, materialized: true

    add_index :reporting_patient_states_per_month, [:assigned_facility_region_id], name: "patient_states_assigned_facility"
    add_index :reporting_patient_states_per_month, [:assigned_block_region_id], name: "patient_states_assigned_block"
    add_index :reporting_patient_states_per_month, [:assigned_district_region_id], name: "patient_states_assigned_district"
    add_index :reporting_patient_states_per_month, [:assigned_state_region_id], name: "patient_states_assigned_state"
    add_index :reporting_patient_states_per_month, [:assigned_organization_region_id], name: "patient_organization_assigned_state"
    add_index :reporting_patient_states_per_month, [:month_date], name: "patient_states_month_date"
    add_index :reporting_patient_states_per_month, [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
  end

  def down
    drop_view :reporting_patient_states_per_month, materialized: true
    drop_view :reporting_patient_visits_per_month, materialized: true
    drop_view :reporting_patient_blood_pressures_per_month, materialized: true
    drop_view :reporting_facilities, materialized: false
    drop_view :reporting_months, materialized: false

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"

    create_view :reporting_months, version: 1, materialized: false
    create_view :reporting_facilities, version: 1, materialized: false
    create_view :reporting_patient_blood_pressures_per_month, version: 1, materialized: true
    create_view :reporting_patient_visits_per_month, version: 2, materialized: true
    create_view :reporting_patient_states_per_month, version: 2, materialized: true

    add_index :reporting_patient_states_per_month, [:assigned_facility_region_id], name: "patient_states_assigned_facility"
    add_index :reporting_patient_states_per_month, [:assigned_block_region_id], name: "patient_states_assigned_block"
    add_index :reporting_patient_states_per_month, [:assigned_district_region_id], name: "patient_states_assigned_district"
    add_index :reporting_patient_states_per_month, [:assigned_state_region_id], name: "patient_states_assigned_state"
    add_index :reporting_patient_states_per_month, [:assigned_organization_region_id], name: "patient_organization_assigned_state"
    add_index :reporting_patient_states_per_month, [:month_date], name: "patient_states_month_date"
    add_index :reporting_patient_states_per_month, [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
  end
end
