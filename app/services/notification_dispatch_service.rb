class NotificationDispatchService
  include Memery

  def initialize(notification, messaging_service)
    @notification = notification
    @messaging_service = messaging_service
    @recipient_number = notification.patient.latest_mobile_number
  end

  attr_reader :notification, :messaging_service, :recipient_number

  def send_message
    return false unless notifiable?(notification)
    case
    when messaging_service == Messaging::Twilio::Sms
      send_as_twilio_sms
    when messaging_service == Messaging::Twilio::Whatsapp
      send_as_twilio_whatsapp
    end
  end

  memoize def message_data
    case notification.purpose
      when "covid_medication_reminder" || "experimental_appointment_reminder" || "missed_visit_reminder"
        notification.message_data
      when "test_message"
        return unless notification.patient

        { message: "Test message sent by Simple.org to #{notification.patient.full_name}",
          vars: {},
          locale: "en-IN" }
      else
        raise ArgumentError, "No message defined for notification of type #{notification.purpose}"
    end
  end



  def send_as_twilio_sms
    handle_twilio_error do
      Messaging::Twilio::Sms.send_message(
        recipient_number: recipient_number,
        message: I18n.t(message_data[:message], **message_data[:vars], locale: message_data[:locale]),
      )
    end
  end

  def send_as_twilio_whatsapp
    handle_twilio_error do
      Messaging::Twilio::Whatsapp.send_message(
        recipient_number: recipient_number,
        message: I18n.t(message_data[:message], **message_data[:vars], locale: message_data[:locale]),
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

  def notifiable?(notification)
    unless notification.status_scheduled?
      logger.info "skipping notification #{notification.id}, scheduled already"
      return
    end

    unless notification.patient.latest_mobile_number
      logger.info "skipping notification #{notification.id}, patient #{notification.patient_id} does not have a mobile number"
      notification.status_cancelled!
      return
    end

    true
  end
end
