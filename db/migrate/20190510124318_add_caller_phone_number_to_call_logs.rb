class AddCallerPhoneNumberToCallLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :call_logs, :caller_phone_number, :string, null: true
  end
end
