class UpdateReportingFacilityStatesToVersion12 < ActiveRecord::Migration[6.1]
  def change
    update_view :reporting_facility_states,
      version: 12,
      revert_to_version: 11,
      materialized: true
  end
end
