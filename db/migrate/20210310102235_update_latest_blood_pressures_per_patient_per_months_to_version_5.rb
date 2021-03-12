class UpdateLatestBloodPressuresPerPatientPerMonthsToVersion5 < ActiveRecord::Migration[5.2]
  def change
    drop_view :latest_blood_pressures_per_patient_per_quarters, materialized: true, revert_to_version: 3
    drop_view :latest_blood_pressures_per_patients, materialized: true, revert_to_version: 1

    update_view :latest_blood_pressures_per_patient_per_months, materialized: true, version: 5, revert_to_version: 4

    create_view :latest_blood_pressures_per_patient_per_quarters, materialized: true, version: 3
    create_view :latest_blood_pressures_per_patients, materialized: true, version: 1
  end
end
