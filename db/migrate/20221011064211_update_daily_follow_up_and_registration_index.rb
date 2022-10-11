class UpdateDailyFollowUpAndRegistrationIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_facility_daily_follow_ups_and_registrations,  [:facility_region_id, :visit_date], unique: true, name: "index_df_facility_region_id_visit_date"
    remove_index :reporting_facility_daily_follow_ups_and_registrations, name: :fd_far_facility_id
    remove_index :reporting_facility_daily_follow_ups_and_registrations, name: :fd_far_visit_date
  end
end
