class VoiceAgent::CallWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(notification_id)
    notification = Notification.find(notification_id)
    return unless notification.status_scheduled?

    Messaging::VoiceAgent::Call.send_message(notification: notification) do |communication|
      notification.record_communication(communication)
    end
  rescue Messaging::MissingReferenceError => error
    cancel(notification, error.message, :no_reference)
  rescue Messaging::VoiceAgent::Error => error
    raise error unless error.reason == :invalid_request

    cancel(notification, error.message, :invalid_request)
  end

  private

  def cancel(notification, message, reason)
    notification.status_cancelled!
    Rails.logger.warn("voice call notification #{notification.id} cancelled. #{message}")
    Metrics.increment("voice_calls_skipped", {reason: reason})
  end
end
