class CreateReportingFacilityStatesByGenders < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_facility_states_by_genders, materialized: true
    add_index :reporting_facility_states_by_genders, [:month_date, :facility_region_id], name: :facility_states_by_gender_month_date_region_id, unique: true
  end
end
