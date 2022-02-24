class NotificationDispatchService
  I_FAIL_ON_ERRORS = [:twilio_invalid_phone_number, :bsnl_random_error]

  def initialize(notification, messaging_service)
    @notification = notification
    @messaging_service = messaging_service
    @recipient_number = notification.patient.latest_mobile_number
  end

  attr_reader :notification, :messaging_service, :recipient_number

  def send_message
    case
    when messaging_service == Messaging::Twilio::Sms
      send_as_twilio_sms
    when messaging_service == Messaging::Twilio::Whatsapp
      send_as_twilio_whatsapp
    end
  end

  def message_data
    case notification.purpose
      when "covid_medication_reminder" || "experimental_appointment_reminder" || "missed_visit_reminder"
        return unless notification.patient

        facility = notification.subject&.facility || notification.patient.assigned_facility
        { message: notification.message,
          vars: { facility_name: facility.name,
                  patient_name: notification.patient.full_name,
                  appointment_date: notification.subject&.scheduled_date&.strftime("%d-%m-%Y") },
          locale: facility.locale }
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
end
