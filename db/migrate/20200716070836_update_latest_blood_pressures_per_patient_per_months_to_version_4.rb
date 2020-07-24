class UpdateLatestBloodPressuresPerPatientPerMonthsToVersion4 < ActiveRecord::Migration[5.2]
  def change
    drop_view :latest_blood_pressures_per_patient_per_quarters, materialized: true, revert_to_version: 2
    drop_view :latest_blood_pressures_per_patients, materialized: true, revert_to_version: 1

    update_view :latest_blood_pressures_per_patient_per_months, version: 4, materialized: true, revert_to_version: 3

    create_view :latest_blood_pressures_per_patient_per_quarters, materialized: true, version: 3
    create_view :latest_blood_pressures_per_patients, materialized: true, version: 1
  end
end
