class UpdateReportingDailyFollowUpsToVersion3 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_daily_follow_ups,
      version: 3,
      revert_to_version: 2,
      materialized: true
  end
end
