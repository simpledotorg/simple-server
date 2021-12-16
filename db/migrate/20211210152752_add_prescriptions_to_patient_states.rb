class AddPrescriptionsToPatientStates < ActiveRecord::Migration[5.2]
  def up
    drop_view :reporting_quarterly_facility_states, materialized: true
    drop_view :reporting_facility_states, materialized: true

    update_view :reporting_patient_states, version: 4, revert_to_version: 3, materialized: true
    add_index :reporting_patient_states, :bp_facility_id, name: "reporting_patient_states_bp_facility_id"
    add_index :reporting_patient_states, :titrated, name: "reporting_patient_states_titrated"
    Reports::PatientState.add_comments

    create_view :reporting_facility_states, version: 3, materialized: true
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :facility_states_month_date_region_id, unique: true

    create_view :reporting_quarterly_facility_states, version: 1, materialized: true
    add_index :reporting_quarterly_facility_states, [:quarter_string, :facility_region_id], name: :quarterly_facility_states_quarter_string_region_id, unique: true
  end

  def down
    drop_view :reporting_quarterly_facility_states, materialized: true
    drop_view :reporting_facility_states, materialized: true

    remove_index :reporting_patient_states, name: "reporting_patient_states_bp_facility_id"
    remove_index :reporting_patient_states, name: "reporting_patient_states_titrated"
    update_view :reporting_patient_states, version: 3, revert_to_version: 2, materialized: true
    Reports::PatientState.add_comments

    create_view :reporting_facility_states, version: 3, materialized: true
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :facility_states_month_date_region_id, unique: true

    create_view :reporting_quarterly_facility_states, version: 1, materialized: true
    add_index :reporting_quarterly_facility_states, [:quarter_string, :facility_region_id], name: :quarterly_facility_states_quarter_string_region_id, unique: true
  end
end
