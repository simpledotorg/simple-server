class AddPatientIdIndexToBpMatViews < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :latest_blood_pressures_per_patient_per_months,
      :patient_id,
      name: "index_latest_bp_per_patient_per_months_patient_id",
      algorithm: :concurrently
    add_index :latest_blood_pressures_per_patient_per_quarters,
      :patient_id,
      name: "index_latest_bp_per_patient_per_quarters_patient_id",
      algorithm: :concurrently
    add_index :latest_blood_pressures_per_patients,
      :patient_id,
      name: "index_latest_bp_per_patient_patient_id",
      algorithm: :concurrently
  end
end
