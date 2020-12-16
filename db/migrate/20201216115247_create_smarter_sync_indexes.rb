class CreateSmarterSyncIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :blood_pressures, :updated_at if index_exists?(:blood_pressures, :updated_at)
    remove_index :blood_sugars, :updated_at if index_exists?(:blood_sugars, :updated_at)
    remove_index :appointments, :updated_at if index_exists?(:appointments, :updated_at)
    remove_index :prescription_drugs, :updated_at if index_exists?(:prescription_drugs, :updated_at)
    remove_index :medical_histories, :updated_at if index_exists?(:medical_histories, :updated_at)
    remove_index :facilities, :updated_at if index_exists?(:facilities, :updated_at)
    remove_index :protocols, :updated_at if index_exists?(:protocols, :updated_at)

    add_index :blood_pressures, [:patient_id, :updated_at]
    add_index :blood_sugars, [:patient_id, :updated_at]
    add_index :appointments, [:patient_id, :updated_at]
    add_index :prescription_drugs, [:patient_id, :updated_at]
    add_index :medical_histories, [:patient_id, :updated_at]
    add_index :facilities, :updated_at
    add_index :protocols, :updated_at
  end
end
