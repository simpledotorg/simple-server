class ReaddIndicesToDependentMatviews < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :latest_blood_pressures_per_patient_per_quarters, :bp_id,
      unique: true,
      name: "index_latest_blood_pressures_per_patient_per_quarters",
      algorithm: :concurrently

    add_index :latest_blood_pressures_per_patient_per_quarters, :patient_id,
      name: "index_latest_bp_per_patient_per_quarters_patient_id",
      algorithm: :concurrently

    add_index :latest_blood_pressures_per_patients, :bp_id,
      unique: true,
      name: "index_latest_blood_pressures_per_patients",
      algorithm: :concurrently

    add_index :latest_blood_pressures_per_patients, :patient_id,
      name: "index_latest_bp_per_patient_patient_id",
      algorithm: :concurrently
  end
end
