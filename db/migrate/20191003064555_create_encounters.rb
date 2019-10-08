class CreateEncounters < ActiveRecord::Migration[5.1]
  def change
    create_table :encounters, id: :uuid do |t|
      t.references :facility, type: :uuid, null: false, foreign_key: true
      t.uuid :patient_id, null: false
      t.references :patient, type: :uuid, null: false, foreign_key: true
      t.date :encountered_on, null: false
      t.integer :timezone_offset, null: false
      t.text :notes
      t.jsonb :metadata

      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
