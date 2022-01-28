class UpdateReportingFacilityStateGroupsToVersion2 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_state_groups,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
