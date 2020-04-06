class AddIndexesToFollowUpsViews < ActiveRecord::Migration[5.1]
  def change
    add_index :latest_blood_pressures_per_patient_per_days, :bp_id, unique: true,
              name: 'index_latest_blood_pressures_per_patient_per_days'
  end
end
