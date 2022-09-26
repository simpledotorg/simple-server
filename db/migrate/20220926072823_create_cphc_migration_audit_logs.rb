class CreateCphcMigrationAuditLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :cphc_migration_audit_logs, id: :uuid do |t|
      t.string :cphc_migratable_type, null: false
      t.uuid :cphc_migratable_id, null: false
      t.json :metadata
      t.timestamps
    end
  end
end
