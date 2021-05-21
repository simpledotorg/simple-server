class AppointmentNotification::ScheduleExperimentReminders < ApplicationJob
  queue_as :high

  def perform
    return unless Flipper.enabled?(:notifications)

    reminders = Notification.due_today
    next_messaging_time = Communication.next_messaging_time
    reminders.each do |reminder|
      reminder.status_scheduled!
      AppointmentNotification::Worker.perform_at(next_messaging_time, reminder.id)
    end
  end
end
