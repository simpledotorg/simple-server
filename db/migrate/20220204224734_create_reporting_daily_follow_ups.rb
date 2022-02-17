class CreateReportingDailyFollowUps < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_daily_follow_ups, materialized: true
    add_index :reporting_daily_follow_ups, [:patient_id, :facility_id, :day_of_year], name: :daily_follow_ups_day_patient_facility, unique: true
  end
end
