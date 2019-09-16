class CreateEncounterEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :encounter_events do |t|
      t.uuid :encounter_id
      t.uuid :user_id
      t.references :encounterable,
                   type: :uuid,
                   polymorphic: true,
                   index: { unique: true,
                            name: 'idx_encounter_events_on_encounterable_type_and_id' }
      t.timestamps
    end
  end
end
