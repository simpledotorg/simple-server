class CreateDiabetesObservations < ActiveRecord::Migration[5.1]
  def change
    create_table :diabetes_observations, id: :uuid do |t|
      t.string :observation_type, null: false, index: true
      t.integer :observation_value, null: false, index: true

      t.uuid :patient_id, null: false, index: true
      t.uuid :user_id, null: false, index: true
      t.uuid :facility_id, null: false, index: true
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.datetime :deleted_at
      t.datetime :recorded_at, null: false
      t.timestamps
    end

    add_foreign_key :diabetes_observations, :master_users, column: :user_id
    add_foreign_key :diabetes_observations, :facilities
  end
end
