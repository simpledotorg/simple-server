class AddIndexForPatientReferences < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :patient_phone_numbers, :patient_id, algorithm: :concurrently
    add_index :blood_pressures, :patient_id, algorithm: :concurrently
    add_index :prescription_drugs, :patient_id, algorithm: :concurrently
  end
end
