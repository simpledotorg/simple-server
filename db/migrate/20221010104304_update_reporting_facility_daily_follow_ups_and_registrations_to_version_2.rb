class UpdateReportingFacilityDailyFollowUpsAndRegistrationsToVersion2 < ActiveRecord::Migration[6.1]
  def change
    update_view :reporting_facility_daily_follow_ups_and_registrations, version: 2, revert_to_version: 1
  end
end
