class CreateBloodPressuresPerFacilityPerDays < ActiveRecord::Migration[5.1]
  def change
    create_view :blood_pressures_per_facility_per_days, materialized: true
  end
end
