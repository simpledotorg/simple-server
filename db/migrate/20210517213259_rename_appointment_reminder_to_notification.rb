class RenameAppointmentReminderToNotification < ActiveRecord::Migration[5.2]
  def change
    rename_table :appointment_reminders, :notifications
    rename_column :communications, :appointment_reminder_id, :notification_id
  end
end
