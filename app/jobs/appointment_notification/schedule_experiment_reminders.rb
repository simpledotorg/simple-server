class AppointmentNotification::ScheduleExperimentReminders < ApplicationJob
  queue_as :high

  def perform
    reminders = AppointmentReminder.due_today
    next_messaging_time = Communication.next_messaging_time
    reminders.each do |reminder|
      AppointmentNotification::Worker.perform_at(next_messaging_time, reminder.id)
      reminder.status_scheduled!
    end
  end
end
