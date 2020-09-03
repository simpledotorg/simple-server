class AddIndexToBpPerMonthsMatView < ActiveRecord::Migration[5.2]
  def change
    add_index :latest_blood_pressures_per_patient_per_months, :patient_recorded_at, name: "index_bp_months_patient_recorded_at"
    add_index :latest_blood_pressures_per_patient_per_months, :medical_history_hypertension, name: "index_bp_months_medical_history_hypertension"
    add_index :latest_blood_pressures_per_patient_per_months, :registration_facility_id, name: "index_bp_months_registration_facility_id"
    add_index :latest_blood_pressures_per_patient_per_months, :bp_recorded_at, name: "index_bp_months_bp_recorded_at"
  end
end
