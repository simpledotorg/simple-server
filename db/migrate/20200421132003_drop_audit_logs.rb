class DropAuditLogs < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    drop_table(:audit_logs)
  end

  def down
    create_table :audit_logs, id: :uuid do |t|
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.uuid :auditable_id, null: false
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, [:action, :auditable_type], algorithm: :concurrently
    add_reference :audit_logs, :user, type: :uuid, null: false
  end
end
