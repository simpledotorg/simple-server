class RemoveUserIdFromCallLogs < ActiveRecord::Migration[5.1]
  def change
    remove_column :call_logs, :user_id, :uuid
  end
end
