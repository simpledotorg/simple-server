class DropCommunicationDeviceColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :communications, :device_created_at
    remove_column :communications, :device_updated_at
    remove_column :communications, :user_id
  end
end
