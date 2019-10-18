class AddActionAndAuditableTypeIndexOnAuditLogs < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :audit_logs, [:action, :auditable_type], algorithm: :concurrently
  end
end
