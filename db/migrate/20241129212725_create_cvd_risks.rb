class CreateCvdRisks < ActiveRecord::Migration[6.1]
  def change
    create_table :cvd_risks, id: :uuid do |t|
      t.integer :risk_score
      t.references :patient, null: false, foreign_key: true, type: :uuid
      t.timestamp :deleted_at
      t.timestamp :device_created_at
      t.timestamp :device_updated_at

      t.timestamps
    end
  end
end
