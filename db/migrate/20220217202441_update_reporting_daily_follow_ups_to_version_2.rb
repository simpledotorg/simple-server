class UpdateReportingDailyFollowUpsToVersion2 < ActiveRecord::Migration[5.2]
  def change
    update_view :reporting_daily_follow_ups,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
