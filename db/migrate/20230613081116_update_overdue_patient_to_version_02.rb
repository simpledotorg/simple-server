class UpdateOverduePatientToVersion02 < ActiveRecord::Migration[6.1]
  def change
    drop_view :reporting_facility_states, materialized: true
    update_view :reporting_overdue_patients,
      version: 2,
      revert_to_version: 1,
      materialized: true
    create_view :reporting_facility_states, materialized: true, version: 11
    add_index :reporting_facility_states, [:month_date, :facility_region_id], name: :index_fs_month_date_region_id, unique: true
    add_index :reporting_facility_states, [:block_region_id, :month_date], name: :index_fs_block_month_date
    add_index :reporting_facility_states, [:district_region_id, :month_date], name: :index_fs_district_month_date
    add_index :reporting_facility_states, [:state_region_id, :month_date], name: :index_fs_state_month_date
    add_index :reporting_facility_states, [:organization_region_id, :month_date], name: :index_fs_organization_month_date
  end
end
