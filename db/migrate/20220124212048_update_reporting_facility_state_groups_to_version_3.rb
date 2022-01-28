class UpdateReportingFacilityStateGroupsToVersion3 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_state_groups,
      version: 3,
      revert_to_version: 2,
      materialized: true
  end
end
