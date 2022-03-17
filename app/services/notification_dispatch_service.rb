class NotificationDispatchService
  include Memery

  def self.call(*args)
    new(*args).call
  end

  def initialize(notification, messaging_channel)
    @notification = notification
    @messaging_channel = messaging_channel
    @recipient_number = notification.patient.latest_mobile_number
  end

  attr_reader :notification, :messaging_channel, :recipient_number

  def call
    if recipient_number.present?
      cancel_notification(reason: :no_mobile_number)
      return
    end

    response = handle_messaging_errors do
      messaging_channel.send_message(
        recipient_number: recipient_number,
        message: notification.localized_message
      )
    end

    log_success
    record_delivery(response)
  end

  private

  def log_success
    communication_type = messaging_channel.communication_type
    Statsd.instance.increment("notifications.sent.#{communication_type}")
    logger.info("notification #{notification.id} communication_type=#{communication_type} sent")
  end

  def record_delivery(response)
    ActiveRecord::Base.transaction do
      notification.status_sent!
      messaging_channel.record_communication(
        recipient_number: recipient_number,
        response: response
      ).tap { |communication| communication.update!(notification: notification) }
    end
  end

  def handle_messaging_errors(&block)
    block.call
  rescue Messaging::Error => error
    if error.reason == :invalid_phone_number
      cancel_notification(reason: :invalid_phone_number)
    else
      raise error
    end
  end

  def cancel_notification(reason:)
    notification.status_cancelled!
    case reason
      when :no_mobile_number
        Rails.logger.info "skipping notification #{notification.id}, patient #{notification.patient_id} does not have a mobile number"
        Statsd.instance.increment("notifications.skipped.no_mobile_number")

      when :invalid_phone_number
        Rails.logger.warn("notification #{notification.id} cancelled because of an invalid phone number")
        Statsd.instance.increment("notifications.skipped.invalid_phone_number")
    end
  end
end
