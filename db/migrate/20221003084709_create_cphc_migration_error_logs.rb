class CreateCphcMigrationErrorLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :cphc_migration_error_logs do |t|
      t.string :cphc_migratable_type, null: false
      t.uuid :cphc_migratable_id, null: false
      t.uuid :facility_id
      t.uuid :patient_id
      t.json :failures
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
