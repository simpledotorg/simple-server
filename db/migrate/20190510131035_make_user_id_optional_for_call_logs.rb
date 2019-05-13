class MakeUserIdOptionalForCallLogs < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:call_logs, :user_id, true)
  end
end
