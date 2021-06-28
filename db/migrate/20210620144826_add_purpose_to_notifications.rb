class AddPurposeToNotifications < ActiveRecord::Migration[5.2]
  def up
    add_column :notifications, :purpose, :string
    Notification.where(subject: nil).find_in_batches do |batch|
      batch.update_all(purpose: :covid_medication_reminder)
    end
    Notification.where.not(subject: nil).find_in_batches do |batch|
      batch.update_all(purpose: :missed_visit_reminder)
    end
    change_column_null :notifications, :purpose, false
  end

  def down
    remove_column :notifications, :purpose
  end
end
