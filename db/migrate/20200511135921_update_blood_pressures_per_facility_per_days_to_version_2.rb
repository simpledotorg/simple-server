class UpdateBloodPressuresPerFacilityPerDaysToVersion2 < ActiveRecord::Migration[5.2]
  def change
    update_view :blood_pressures_per_facility_per_days,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
