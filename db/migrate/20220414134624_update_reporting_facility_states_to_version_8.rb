class UpdateReportingFacilityStatesToVersion8 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_states,
      version: 8,
      revert_to_version: 7,
      materialized: true
  end
end
