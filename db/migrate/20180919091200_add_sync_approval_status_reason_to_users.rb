class AddSyncApprovalStatusReasonToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :sync_approval_status_reason, :text, null: true
  end
end
