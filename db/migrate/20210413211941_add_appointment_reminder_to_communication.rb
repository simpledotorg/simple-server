class AddAppointmentReminderToCommunication < ActiveRecord::Migration[5.2]
  def change
    add_reference :communications, :appointment_reminder, type: :uuid, foreign_key: true
  end
end
