class UpdateReportingFacilityStatesByGendersToVersion2 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_states_by_genders, version: 2, revert_to_version: 1, materialized: true
  end
end
