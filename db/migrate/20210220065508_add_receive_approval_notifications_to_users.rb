class AddReceiveApprovalNotificationsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :receive_approval_notifications, :boolean, null: false, default: true
  end
end
