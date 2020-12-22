class AddCompositeSyncIndexes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :patients, [:id, :updated_at], algorithm: :concurrently
    add_index :appointments, [:patient_id, :updated_at], algorithm: :concurrently
    add_index :blood_sugars, [:patient_id, :updated_at], algorithm: :concurrently
    add_index :blood_pressures, [:patient_id, :updated_at], algorithm: :concurrently
    add_index :encounters, [:patient_id, :updated_at], algorithm: :concurrently
    add_index :medical_histories, [:patient_id, :updated_at], algorithm: :concurrently
    add_index :prescription_drugs, [:patient_id, :updated_at], algorithm: :concurrently
    add_index :protocols, :updated_at, algorithm: :concurrently
    add_index :facilities, :updated_at, algorithm: :concurrently
  end
end
