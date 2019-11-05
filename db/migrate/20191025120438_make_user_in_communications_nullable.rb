class MakeUserInCommunicationsNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:communications, :user_id, true)
  end
end
