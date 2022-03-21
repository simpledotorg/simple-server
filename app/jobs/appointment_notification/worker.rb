class AppointmentNotification::Worker
  include Sidekiq::Worker
  include Memery
  APPOINTMENT_REMINDERS_CHANNEL = CountryConfig.current[:appointment_reminders_channel]

  sidekiq_options queue: :high

  def perform(notification_id)
    return unless flipper_enabled?

    notification = Notification.find(notification_id)

    if scheduled?(notification)
      NotificationDispatchService.call(notification, APPOINTMENT_REMINDERS_CHANNEL)
    end
  end

  private

  def scheduled?(notification)
    return true if notification.status_scheduled?

    Rails.logger.info "skipping notification #{notification.id}, scheduled already"
    Statsd.instance.increment("notifications.skipped.not_scheduled")
  end

  def flipper_enabled?
    Statsd.instance.increment("notifications.attempts")
    return true if Flipper.enabled?(:notifications) || Flipper.enabled?(:experiment)

    Rails.logger.warn "notifications or experiment feature flag are disabled"
    Statsd.instance.increment("notifications.skipped.feature_disabled")
    false
  end
end
