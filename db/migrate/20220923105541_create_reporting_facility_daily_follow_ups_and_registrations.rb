class CreateReportingFacilityDailyFollowUpsAndRegistrations < ActiveRecord::Migration[5.2]
  def change
    drop_view :reporting_daily_follow_ups, revert_to_version: 3, materialized: true
    create_view :reporting_facility_daily_follow_ups_and_registrations, materialized: true
    add_index :reporting_facility_daily_follow_ups_and_registrations, [:facility_id, :visit_date], name: :fd_far_facility_id_visit_date, unique: true
    add_index :reporting_facility_daily_follow_ups_and_registrations, :facility_id, name: :fd_far_facility_id
    add_index :reporting_facility_daily_follow_ups_and_registrations, :visit_date, name: :fd_far_visit_date
  end
end
