class AddReportingFacilityStateRegionIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_facility_states, [:month_date, :organization_region_id], name: :index_fs_month_date_organization
    add_index :reporting_facility_states, [:month_date, :state_region_id], name: :index_fs_month_date_state
    add_index :reporting_facility_states, [:month_date, :district_region_id], name: :index_fs_month_date_district
    add_index :reporting_facility_states, [:month_date, :block_region_id], name: :index_fs_month_date_block
  end
end
