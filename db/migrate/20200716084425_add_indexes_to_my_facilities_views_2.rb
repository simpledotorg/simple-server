class AddIndexesToMyFacilitiesViews2 < ActiveRecord::Migration[5.1]
  def change
    add_index :latest_blood_pressures_per_patient_per_quarters, :bp_id, unique: true,
              name: "index_latest_blood_pressures_per_patient_per_quarters"
    add_index :latest_blood_pressures_per_patients, :bp_id, unique: true,
              name: "index_latest_blood_pressures_per_patients"
  end
end
