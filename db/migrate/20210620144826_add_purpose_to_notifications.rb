class AddPurposeToNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :notifications, :purpose, :string
    Notification.find_each do |notification|
      notification.update_column(:purpose, "covid_medication_reminder")
    end
    change_column_null :notifications, :purpose, false
  end

  def down
    remove_column :notifications, :purpose
  end
end
