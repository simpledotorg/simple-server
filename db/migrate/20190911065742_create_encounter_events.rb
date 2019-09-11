class CreateEncounterEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :encounter_events do |t|
      t.uuid :encounter_id
      t.uuid :user_id
      t.references :encountered, type: :uuid, polymorphic: true, index: { unique: true }

      t.timestamps
    end
  end
end
