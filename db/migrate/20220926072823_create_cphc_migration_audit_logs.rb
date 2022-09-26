class CreateCphcMigrationAuditLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :cphc_migration_audit_logs, id: :uuid do |t|
      t.string :cphc_migratable_type, null: false
      t.uuid :cphc_migratable_id, null: false
      t.json :metadata
      t.timestamps
    end
    add_index :cphc_migration_audit_logs,
      [:cphc_migratable_type, :cphc_migratable_id],
      unique: true,
      name: "index_cphc_migration_audit_logs_on_cphc_migratable"
  end
end
