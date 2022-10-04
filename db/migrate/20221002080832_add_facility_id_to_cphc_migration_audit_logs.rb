class AddFacilityIdToCphcMigrationAuditLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :cphc_migration_audit_logs, :facility_id, :uuid
  end
end
