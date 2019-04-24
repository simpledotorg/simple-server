class CreatePatientBusinessIdentifiers < ActiveRecord::Migration[5.1]
  def change
    create_table :patient_business_identifiers, id: :uuid do |t|
      t.string :identifier, null: false
      t.string :identifier_type, null: false
      t.belongs_to :patient, type: :uuid, null: false
      t.string :metadata_version
      t.json :metadata

      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :patient_business_identifiers, :deleted_at
  end
end
