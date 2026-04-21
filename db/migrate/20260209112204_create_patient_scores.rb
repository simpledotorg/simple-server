class CreatePatientScores < ActiveRecord::Migration[6.1]
  def up
    create_table :patient_scores, id: :uuid do |t|
      t.references :patient, null: false, foreign_key: true, type: :uuid
      t.string :score_type, null: false, limit: 100
      t.decimal :score_value, precision: 5, scale: 2, null: false
      t.datetime :device_created_at, null: false
      t.datetime :device_updated_at, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :patient_scores, [:patient_id, :score_type]
    add_index :patient_scores, :updated_at
  end

  def down
    drop_table :patient_scores
  end
end
