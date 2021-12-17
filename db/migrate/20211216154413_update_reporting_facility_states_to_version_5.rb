class UpdateReportingFacilityStatesToVersion5 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_states,
      version: 5,
      revert_to_version: 4,
      materialized: true
  end
end
