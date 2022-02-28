class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  class UnknownCommunicationType < StandardError
  end

  def metrics
    @metrics ||= Metrics.with_object(self)
  end

  def logger
    @logger ||= Notification.logger(class: self.class.name)
  end

  def perform(notification_id, phone_number = nil)
    return unless flipper_enabled?

    notification = Notification.includes(:subject, :patient).find(notification_id)
    patient = notification.patient
    Sentry.set_tags(patient_id: patient.id)

    return unless valid_notification?(notification)
    send_message(notification, phone_number || patient.latest_mobile_number)
  end

  private

  def send_message(notification, recipient_number)
    communication_type = notification.next_communication_type
    logger.info "send_message for notification #{notification.id} communication_type=#{communication_type}"
    context = {
      calling_class: self.class.name,
      notification_id: notification.id,
      notification_purpose: notification.purpose,
      communication_type: communication_type
    }
    Sentry.set_tags(context)

    response = notify_via_twilio(notification, communication_type, recipient_number, context)

    return unless response
    metrics.increment("sent.#{communication_type}")

    ActiveRecord::Base.transaction do
      create_communication(notification, communication_type, response)
      notification.status_sent!
    end
    logger.info("notification #{notification.id} communication_type=#{communication_type} sent")
    response
  end

  def notify_via_twilio(notification, communication_type, recipient_number, context)
    service = TwilioApiService.new(sms_sender: medication_reminder_sms_sender)
    args = {
      recipient_number: recipient_number,
      message: notification.localized_message,
      callback_url: callback_url,
      context: context
    }

    handle_twilio_error(notification) do
      case communication_type
      when "whatsapp"
        service.send_whatsapp(args)
      when "sms"
        service.send_sms(args)
      else
        raise UnknownCommunicationType, "#{self.class.name} is not configured to handle communication type #{communication_type}"
      end
    end
  end

  def handle_twilio_error(notification, &block)
    block.call
  rescue TwilioApiService::Error => error
    if error.reason == :invalid_phone_number
      notification.status_cancelled!
      logger.warn("notification #{notification.id} cancelled because of an invalid phone number")
      Statsd.instance.increment("twilio.errors.invalid_phone_number")
      false
    else
      raise error
    end
  end

  def create_communication(notification, communication_type, response)
    Communication.create_with_twilio_details!(
      appointment: notification.subject,
      notification: notification,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: communication_type
    )
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end

  def medication_reminder_sms_sender
    @medication_reminder_sms_sender ||= medication_reminder_sms_senders.sample
  end

  def medication_reminder_sms_senders
    ENV.fetch("TWILIO_APPOINTMENT_REMINDER_NUMBERS", "").split(",").map(&:strip)
  end

  def valid_notification?(notification)
    unless notification.next_communication_type
      logger.info "skipping notification #{notification.id}, no next communication type"
      metrics.increment("skipped.no_next_communication_type")
      return
    end

    unless notification.status_scheduled?
      logger.info "skipping notification #{notification.id}, scheduled already"
      metrics.increment("skipped.not_scheduled")
      return
    end

    unless notification.patient.latest_mobile_number
      logger.info "skipping notification #{notification.id}, patient #{notification.patient_id} does not have a mobile number"
      metrics.increment("skipped.no_mobile_number")
      notification.status_cancelled!
      return
    end

    true
  end

  def flipper_enabled?
    metrics.increment("attempts")
    return true if Flipper.enabled?(:notifications) || Flipper.enabled?(:experiment)

    logger.warn "notifications or experiment feature flag are disabled"
    metrics.increment("skipped.feature_disabled")
    false
  end
end
