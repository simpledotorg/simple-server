class AppointmentNotification::ScheduleExperimentReminders < ApplicationJob
  queue_as :high

  def logger
    @logger ||= Notification.logger(class: self.class.name)
  end

  def perform
    return unless Flipper.enabled?(:experiment)

    notifications = Notification.due_today
    next_messaging_time = Communication.next_messaging_time

    logger.info "scheduling #{notifications.count} notifications that are due with next_messaging_time=#{next_messaging_time}"
    notifications.each do |notification|
      notification.status_scheduled!
      AppointmentNotification::Worker.perform_at(next_messaging_time, notification.id)
    rescue => e
      Sentry.capture_message("Scheduling notification failed",
        extra: {
          notification: notification.id,
          next_messaging_time: next_messaging_time,
          exception: e
        },
        tags: {type: "notifications"})
    end
    logger.info "scheduling experiment notifications complete"
  end
end
