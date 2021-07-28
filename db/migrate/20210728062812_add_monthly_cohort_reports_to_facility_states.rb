class AddMonthlyCohortReportsToFacilityStates < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_facility_states, version: 3, revert_to_version: 2, materialized: true
  end
end
