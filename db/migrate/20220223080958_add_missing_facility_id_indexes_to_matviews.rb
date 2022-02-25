class AddMissingFacilityIdIndexesToMatviews < ActiveRecord::Migration[5.2]
  def change
    add_index :reporting_facility_state_dimensions, [:facility_id], name: :index_fs_dimensions_facility_id
    add_index :reporting_quarterly_facility_states, [:facility_id], name: :index_qfs_facility_id
    add_index :reporting_daily_follow_ups, [:facility_id], name: :index_dfu_facility_id
  end
end
