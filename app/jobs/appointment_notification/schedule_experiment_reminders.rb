class AppointmentNotification::ScheduleExperimentReminders < ApplicationJob
  queue_as :high
  class << self
    prepend SentryHandler
  end

  def self.call
    perform_now
  end

  def logger
    @logger ||= Notification.logger(class: self.class.name)
  end

  def perform
    return unless Flipper.enabled?(:experiment)

    reminders = ExperimentalAppointmentReminder.due_today
    next_messaging_time = Communication.next_messaging_time

    logger.info "scheduling #{notifications.count} notifications that are due with next_messaging_time=#{next_messaging_time}"
    reminders.each do |reminder|
      reminder.status_scheduled!
      AppointmentNotification::Worker.perform_at(next_messaging_time, reminder.id)
    rescue => e
      Sentry.capture_message("Scheduling reminder for experiment failed",
        extra: {
          reminder: reminder.id,
          next_messaging_time: next_messaging_time,
          exception: e
        },
        tags: {type: "reminders"})
    end
    logger.info "scheduling experiment reminders complete"
  end
end
