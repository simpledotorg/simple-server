class UpdateReportingFacilityStatesToVersion10 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_states,
      version: 10,
      revert_to_version: 9,
      materialized: true
  end
end
