class AddConfiguredMessageToNotifications < ActiveRecord::Migration[5.2]
  def change
    add_column :notifications, :configured_message, :string
  end
end
