class CreateObservations < ActiveRecord::Migration[5.1]
  def change
    create_table :observations do |t|
      t.references :encounter, type: :uuid, null: false, foreign_key: true
      t.uuid :user_id
      t.references :observable,
                   type: :uuid,
                   polymorphic: true,
                   index: { unique: true,
                            name: 'idx_observations_on_observable_type_and_id' }
      t.timestamps
    end
  end
end
