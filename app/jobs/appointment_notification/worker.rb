class AppointmentNotification::Worker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :high
  sidekiq_throttle(
    threshold: {limit: 600, period: 1.minute}
  )

  def perform(notification_id)
    return unless flipper_enabled?

    notification = Notification.find(notification_id)

    NotificationDispatchService.call(notification) if scheduled?(notification)
  end

  private

  def scheduled?(notification)
    return true if notification.status_scheduled?

    Rails.logger.info "skipping notification #{notification.id}, scheduled already"
    Metrics.increment("notifications_skipped", {reason: "not_scheduled"})
  end

  def flipper_enabled?
    Metrics.increment("notifications_attempts")
    return true if Flipper.enabled?(:notifications) || Flipper.enabled?(:experiment)

    Rails.logger.warn "notifications or experiment feature flag are disabled"
    Metrics.increment("notifications_skipped", {reason: "feature_disabled"})
    false
  end
end
