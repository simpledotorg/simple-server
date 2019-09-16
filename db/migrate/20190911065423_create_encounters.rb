class CreateEncounters < ActiveRecord::Migration[5.1]
  def change
    create_table :encounters, id: :uuid do |t|
      t.uuid :facility_id, null: false
      t.uuid :patient_id, null: false
      t.date :encountered_on, null: false
      t.text :timezone, null: false
      t.integer :timezone_offset, null: false
      t.jsonb :metadata

      t.datetime :recorded_at, null: false
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false

      t.timestamps
    end
  end
end
