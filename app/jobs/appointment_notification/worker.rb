class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high
  delegate :logger, to: Rails

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
      metrics.increment("skipped.previously_communicated")
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
    if notification.experiment&.experiment_type == "medication_reminder" && medication_reminder_sms_sender
      notification_service = NotificationService.new(sms_sender: medication_reminder_sms_sender)
    else
      notification_service = NotificationService.new
    end


    if communication_type == "missed_visit_whatsapp_reminder"
      notification_service.send_whatsapp(
        notification.patient.latest_mobile_number,
        notification.localized_message,
        callback_url
      ).tap do |response|
        metrics.increment("sent.whatsapp")
      end
    else
      notification_service.send_sms(
        notification.patient.latest_mobile_number,
        notification.localized_message,
        callback_url
      ).tap do |response|
        metrics.increment("sent.sms")
      end
    end

    logger.info class: self.class.name, msg: "send_message", failed: !!notification_service.failed?,
                communication_type: communication_type, notification_id: notification.id

    return if notification_service.failed?

    ActiveRecord::Base.transaction do
      create_communication(notification, communication_type, notification_service.response)
      notification.status_sent!
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
    ENV.fetch("TWILIO_COVID_REMINDER_NUMBERS", "").split(",").map(&:strip)
  end
end
