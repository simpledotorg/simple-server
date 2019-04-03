class RemoveActionFromCallLogs < ActiveRecord::Migration[5.1]
  def change
    remove_column :call_logs, :action, :string
  end
end
