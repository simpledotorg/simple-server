class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high
  delegate :logger, to: Rails

  class UnknownCommunicationType < StandardError
  end

  def metrics
    @metrics ||= Metrics.with_object(self)
  end

  def perform(notification_id)
    metrics.increment("attempts")
    unless Flipper.enabled?(:notifications) || Flipper.enabled?(:experiment)
      logger.info class: self.class.name, msg: "notifications feature is disabled"
      metrics.increment("skipped.feature_disabled")
      return
    end

    notification = Notification.includes(:subject, :patient).find(notification_id)
    communication_type = notification.next_communication_type
    unless communication_type
      metrics.increment("skipped.no_next_communication_type")
      return
    end

    unless notification.status_scheduled?
      metrics.increment("skipped.not_scheduled")
      return
    end

    send_message(notification, communication_type)
  end

  private

  def send_message(notification, communication_type)
    notification_service = if communication_type == "imo"
      ImoApiService.new
    elsif notification.experiment&.experiment_type == "medication_reminder" && medication_reminder_sms_sender
      TwilioApiService.new(sms_sender: medication_reminder_sms_sender)
    else
      TwilioApiService.new
    end

    context = {
      calling_class: self.class.name,
      notification_id: notification.id,
      communication_type: communication_type
    }

    # remove missed_visit_whatsapp_reminder and missed_visit_sms_reminder
    # https://app.clubhouse.io/simpledotorg/story/3585/backfill-notifications-from-communications
    response = case communication_type
    when "whatsapp", "missed_visit_whatsapp_reminder"
      notification_service.send_whatsapp(
        recipient_number: notification.patient.latest_mobile_number,
        message: notification.localized_message,
        callback_url: callback_url,
        context: context
      )
    when "sms", "missed_visit_sms_reminder"
      notification_service.send_sms(
        recipient_number: notification.patient.latest_mobile_number,
        message: notification.localized_message,
        callback_url: callback_url,
        context: context
      )
    when "imo"
      notification_service.send_notification(notification.patient, notification.localized_message)
    else
      raise UnknownCommunicationType, "#{self.class.name} is not configured to handle communication type #{communication_type}"
    end

    metrics.increment("sent.#{communication_type}")
    return unless response

    ActiveRecord::Base.transaction do
      create_communication(notification, communication_type, response)
      notification.status_sent!
    end
  end

  def create_communication(notification, communication_type, response)
    if communication_type == "imo"
      Communication.create_with_imo_details!(
        appointment: notification.subject,
        notification: notification
      )
    else
      Communication.create_with_twilio_details!(
        appointment: notification.subject,
        notification: notification,
        twilio_sid: response.sid,
        twilio_msg_status: response.status,
        communication_type: communication_type
      )
    end
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
    ENV.fetch("TWILIO_COVID_REMINDER_NUMBERS", "").split(",").map(&:strip)
  end
end
