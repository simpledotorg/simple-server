class CreatePatientScores < ActiveRecord::Migration[6.1]
  def change
    unless table_exists?(:patient_scores)
      create_table :patient_scores, id: :uuid do |t|
        t.references :patient, null: false, foreign_key: true, type: :uuid
        t.string :score_type, null: false, limit: 100
        t.decimal :score_value, precision: 5, scale: 2, null: false
        t.datetime :device_created_at, null: false
        t.datetime :device_updated_at, null: false
        t.datetime :deleted_at

        t.timestamps
      end
    end

    unless index_exists?(:patient_scores, [:patient_id, :score_type])
      add_index :patient_scores, [:patient_id, :score_type]
    end

    unless index_exists?(:patient_scores, :updated_at)
      add_index :patient_scores, :updated_at
    end
  end
end
