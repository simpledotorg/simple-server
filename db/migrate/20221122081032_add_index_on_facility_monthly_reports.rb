class AddIndexOnFacilityMonthlyReports < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_facility_monthly_follow_ups_and_registrations, [:facility_region_id], name: :facility_monthly_fr_facility_region_id
  end
end
