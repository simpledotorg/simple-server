class UpdateLatestBloodPressuresPerPatientPerQuartersToVersion2 < ActiveRecord::Migration[5.1]
  def change
    update_view :latest_blood_pressures_per_patient_per_quarters,
      version: 2,
      revert_to_version: 1,
      materialized: true
  end
end
