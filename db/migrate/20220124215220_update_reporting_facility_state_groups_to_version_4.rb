class UpdateReportingFacilityStateGroupsToVersion4 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_state_groups,
      version: 4,
      revert_to_version: 3,
      materialized: true
  end
end
