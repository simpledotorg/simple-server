class DropAuditLogs < ActiveRecord::Migration[5.1]
  def change
    drop_table(:audit_logs)
  end
end
