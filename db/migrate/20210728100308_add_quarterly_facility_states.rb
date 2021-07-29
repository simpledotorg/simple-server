class AddQuarterlyFacilityStates < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_quarterly_facility_states, version: 1, materialized: true
    add_index :reporting_quarterly_facility_states, [:quarter_string, :facility_region_id], name: :quarterly_facility_states_quarter_string_region_id, unique: true
  end
end
