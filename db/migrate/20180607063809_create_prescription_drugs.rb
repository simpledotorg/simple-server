class CreatePrescriptionDrugs < ActiveRecord::Migration[5.1]
  def change
    create_table :prescription_drugs, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :name, null: false
      t.string :rxnorm_code
      t.string :dosage
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.timestamps
      t.uuid :patient_id, null: false
      t.uuid :facility_id, null: false
    end
  end
end
