class UpdateReportingFacilityStatesToVersion6 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_states,
      version: 6,
      revert_to_version: 5,
      materialized: true
  end
end
