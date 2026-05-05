class CreatePatientScores < ActiveRecord::Migration[6.1]
  REQUIRED_COLUMNS = %i[patient_id score_type score_value device_created_at device_updated_at deleted_at].freeze

  def up
    if table_exists?(:patient_scores) && !schema_complete?
      say "Dropping patient_scores table due to incomplete schema"
      drop_table :patient_scores
    end

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

    add_index :patient_scores, [:patient_id, :score_type], unique: true unless index_exists?(:patient_scores, [:patient_id, :score_type])
    add_index :patient_scores, :updated_at unless index_exists?(:patient_scores, :updated_at)
  end

  def down
    drop_table :patient_scores, if_exists: true
  end

  private

  def schema_complete?
    REQUIRED_COLUMNS.all? { |col| column_exists?(:patient_scores, col) }
  end
end
