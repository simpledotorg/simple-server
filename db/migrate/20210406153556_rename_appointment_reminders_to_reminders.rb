class RenameAppointmentRemindersToReminders < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:appointment_reminders, :appointment_id, true)
    rename_table :appointment_reminders, :reminders
  end
end
