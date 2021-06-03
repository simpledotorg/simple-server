class UpdateLatestBloodPressuresPerPatientPerMonthsToVersion6 < ActiveRecord::Migration[5.2]
  def change
    drop_view :latest_blood_pressures_per_patients, materialized: true, revert_to_version: 1
    drop_view :latest_blood_pressures_per_patient_per_quarters, materialized: true, revert_to_version: 3

    update_view :latest_blood_pressures_per_patient_per_months, version: 6, revert_to_version: 5, materialized: true

    create_view :latest_blood_pressures_per_patient_per_quarters, materialized: true, version: 3
    create_view :latest_blood_pressures_per_patients, materialized: true, version: 1

    add_index "latest_blood_pressures_per_patient_per_quarters", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_quarters", unique: true
    add_index "latest_blood_pressures_per_patient_per_quarters", ["patient_id"], name: "index_latest_bp_per_patient_per_quarters_patient_id"
    add_index "latest_blood_pressures_per_patients", ["bp_id"], name: "index_latest_blood_pressures_per_patients", unique: true
    add_index "latest_blood_pressures_per_patients", ["patient_id"], name: "index_latest_bp_per_patient_patient_id"
  end
end
