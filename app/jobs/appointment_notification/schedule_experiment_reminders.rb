class AppointmentNotification::ScheduleExperimentReminders < ApplicationJob
  queue_as :high

  def perform
    reminders = AppointmentReminder.due_today
    next_messaging_time = Communication.next_messaging_time
    # remove this later
    communication_type = "missed_visit_whatsapp_reminder"
    reminders.each do |reminder|
      AppointmentNotification::Worker.perform_at(next_messaging_time, reminder.id, communication_type)
      reminder.status_scheduled!
    end
  end
end
