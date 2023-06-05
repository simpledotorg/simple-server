class UpdateReportingFacilityStatesToVersion11 < ActiveRecord::Migration[6.1]
  def change
    update_view :reporting_facility_states,
      version: 11,
      revert_to_version: 10,
      materialized: true
  end
end
