class MakeCallerPhoneNumberInCallLogsNotNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:call_logs, :caller_phone_number, false)
  end
end
