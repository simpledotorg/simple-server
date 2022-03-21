class NotificationDispatchService
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
    if recipient_number.blank?
      cancel_no_mobile_notification
      return
    end

    handle_messaging_errors {
      messaging_channel.send_message(
        recipient_number: recipient_number,
        message: notification.localized_message,
      ) { |communication| notification.record_communication(communication) }
    }.tap { log_success }
  end

  private

  def log_success
    communication_type = messaging_channel.communication_type
    Statsd.instance.increment("notifications.sent.#{communication_type}")
    Rails.logger.info("notification #{notification.id} communication_type=#{communication_type} sent")
  end

  def handle_messaging_errors(&block)
    block.call
  rescue Messaging::Error => error
    if error.reason == :invalid_phone_number
      cancel_invalid_number_notification
    else
      raise error
    end
  end

  def cancel_no_mobile_notification
    notification.status_cancelled!
    Rails.logger.info "skipping notification #{notification.id}, patient #{notification.patient_id} does not have a mobile number"
    Statsd.instance.increment("notifications.skipped.no_mobile_number")
  end

  def cancel_invalid_number_notification
    notification.status_cancelled!
    Rails.logger.warn("notification #{notification.id} cancelled because of an invalid phone number")
    Statsd.instance.increment("notifications.skipped.invalid_phone_number")
  end
end
