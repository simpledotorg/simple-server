class AddReceiveApprovalEmailsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :receive_approval_emails, :boolean, null: false, default: true
  end
end
