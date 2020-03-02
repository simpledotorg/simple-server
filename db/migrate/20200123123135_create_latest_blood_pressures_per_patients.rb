class CreateLatestBloodPressuresPerPatients < ActiveRecord::Migration[5.1]
  def change
    create_view :latest_blood_pressures_per_patients, materialized: true
  end
end
