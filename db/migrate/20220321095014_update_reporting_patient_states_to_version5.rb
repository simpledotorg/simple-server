class UpdateReportingPatientStatesToVersion5 < ActiveRecord::Migration[5.2]
  def change
    drop_view :reporting_facility_state_dimensions, materialized: true
    drop_view :reporting_facility_states, materialized: true
    drop_view :reporting_quarterly_facility_states, materialized: true

    update_view :reporting_patient_states,
      version: 5,
      revert_to_version: 4,
      materialized: true

    create_view :reporting_facility_state_dimensions, materialized: true, version: 1
    add_index :reporting_facility_state_dimensions, [:month_date, :facility_region_id], name: :index_fs_dimensions_month_date_facility_region_id, unique: true
    add_index :reporting_facility_state_dimensions, [:facility_id], name: :index_fs_dimensions_facility_id

    create_view :reporting_facility_states, materialized: true, version: 7
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :index_fs_month_date_region_id, unique: true

    create_view :reporting_quarterly_facility_states, version: 1, materialized: true
    add_index :reporting_quarterly_facility_states, [:quarter_string, :facility_region_id], name: :index_qfs_quarter_string_region_id, unique: true
    add_index :reporting_quarterly_facility_states, [:facility_id], name: :index_qfs_facility_id
  end
end
