class UpdateReportingFacilityStateGroupsToVersion4 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_state_groups,
      version: 4,
      revert_to_version: 3,
      materialized: true
    unless index_exists?(:reporting_facility_state_groups, :facility_state_groups_month_date_region_id)
      add_index :reporting_facility_state_groups, [:month_date, :facility_region_id], name: :facility_state_groups_month_date_region_id, unique: true
    end
  end
end
