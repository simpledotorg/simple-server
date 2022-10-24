class AddReportingFacilityStateRegionIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_facility_states, [:organization_region_id, :month_date], name: :index_fs_organization_month_date
    add_index :reporting_facility_states, [:state_region_id, :month_date], name: :index_fs_state_month_date
    add_index :reporting_facility_states, [:district_region_id, :month_date], name: :index_fs_district_month_date
    add_index :reporting_facility_states, [:block_region_id, :month_date], name: :index_fs_block_month_date
  end
end
