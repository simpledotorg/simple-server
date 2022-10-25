class CreateReportingFacilityMonthlyFollowUpsAndRegistrations < ActiveRecord::Migration[6.1]
  def change
    drop_view :reporting_facility_state_dimensions, revert_to_version: 1, materialized: true
    create_view :reporting_facility_monthly_follow_ups_and_registrations, materialized: true
    add_index :reporting_facility_monthly_follow_ups_and_registrations, [:month_date, :facility_region_id], name: :facility_monthly_fr_month_date_facility_region_id, unique: true
    add_index :reporting_facility_monthly_follow_ups_and_registrations, [:facility_id], name: :facility_monthly_fr_facility_id
  end
end
