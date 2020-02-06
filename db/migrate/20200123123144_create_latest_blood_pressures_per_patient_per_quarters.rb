class CreateLatestBloodPressuresPerPatientPerQuarters < ActiveRecord::Migration[5.1]
  def change
    create_view :latest_blood_pressures_per_patient_per_quarters, materialized: true
  end
end
