class AddPurposeToNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :notifications, :purpose, :string
    Notification.where(subject: nil).update_all(purpose: :covid_medication_reminder)
    Notification.where.not(subject: nil).update_all(purpose: :missed_visit_reminder)
    change_column_null :notifications, :purpose, false
  end

  def down
    remove_column :notifications, :purpose
  end
end
