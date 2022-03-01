class NotificationDispatchService
  include Memery

  def initialize(notification, messaging_service)
    @notification = notification
    @messaging_service = messaging_service
    @recipient_number = notification.patient.latest_mobile_number
  end

  attr_reader :notification, :messaging_service, :recipient_number

  def send_message
    return false unless notifiable?
    case
    when messaging_service == Messaging::Twilio::Sms
      send_as_twilio_sms
    when messaging_service == Messaging::Twilio::Whatsapp
      send_as_twilio_whatsapp
    end

    notification.status_sent!
  end

  def record_communication(notification)
    ActiveRecord::Base.transaction do
      create_communication(notification, messaging_service.communication_type)
    end
  end

  def create_communication(notification, communication_type)
    messaging_service.create_communication(communication_type: communication_type,
            appointment: appointment,
            notification: notification,
            device_created_at: now,
            device_updated_at: now)
  end

  memoize def message_data
    notification.message_data
  end

  def send_as_twilio_sms
    handle_twilio_error do
      Messaging::Twilio::Sms.send_message(
        recipient_number: recipient_number,
        message: notification.localized_message,
        communication_type: "sms"
      )
    end
  end

  def send_as_twilio_whatsapp
    handle_twilio_error do
      Messaging::Twilio::Whatsapp.send_message(
        recipient_number: recipient_number,
        message: notification.localized_message,
        communication_type: "whatsapp"
      )
    end
  end

  def handle_twilio_error(&block)
    block.call
  rescue Messaging::Twilio::Api::Error => error
    if error.reason == :invalid_phone_number
      notification.status_cancelled!
      logger.warn("notification #{notification.id} cancelled because of an invalid phone number")
      Statsd.instance.increment("twilio.errors.invalid_phone_number")
      false
    else
      raise error
    end
  end
end
