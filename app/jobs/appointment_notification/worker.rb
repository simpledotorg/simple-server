class AppointmentNotification::Worker
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def metrics
    @metrics ||= Metrics.with_object(self)
  end

  def perform(notification_id)
    return unless flipper_enabled?

    notification = Notification.includes(:subject, :patient).find(notification_id)
    patient = notification.patient
    Sentry.set_tags(patient_id: patient.id)

    return unless valid_notification?(notification)
    send_message(notification, patient.latest_mobile_number)
  end

  private

  def send_message(notification, recipient_number)
    response = notify(notification, recipient_number)
    return unless response

    ActiveRecord::Base.transaction do
      create_communication(notification, response)
      notification.status_sent!
    end

    log_notification_sent
    response
  end

  def log_notification_sent
    communication_type = appointment_reminders_channel.communication_type
    metrics.increment("sent.#{communication_type}")
    logger.info("notification #{notification.id} communication_type=#{communication_type} sent")
  end

  def notify(notification, recipient_number)
    handle_messaging_error(notification) do
      appointment_reminders_channel.send_message(recipient_number: recipient_number, message: notification.localized_message)
    end
  end

  memoize def appointment_reminders_channel
    CountryConfig.current[:appointment_reminders_channel]
  end

  def handle_messaging_error(notification, &block)
    block.call
  rescue Messaging::Error => error
    if error.reason == :invalid_phone_number
      notification.status_cancelled!
      logger.warn("notification #{notification.id} cancelled because of an invalid phone number")
      Statsd.instance.increment("twilio.errors.invalid_phone_number")
      false
    else
      raise error
    end
  end

  def create_communication(notification, response)
    Communication.create_with_twilio_details!(
      notification: notification,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: appointment_reminders_channel.communication_type
    )
  end

  def valid_notification?(notification)
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
