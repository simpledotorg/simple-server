class CreateReportingFacilityStateGroups < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_facility_state_groups, materialized: true
    add_index :reporting_facility_state_groups, [:month_date, :facility_region_id], name: :facility_state_groups_month_date_region_id, unique: true
  end
end
