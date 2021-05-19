class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def metrics
    @metrics ||= Metrics.with_object(self)
  end

  def perform(notification_id)
    metrics.increment("attempts")
    unless Flipper.enabled?(:notifications)
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
    notification_service = NotificationService.new

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

    return if notification_service.failed?

    ActiveRecord::Base.transaction do
      create_communication(notification, communication_type, notification_service.response)
      notification.status_sent!
    end
  end

  def create_communication(notification, communication_type, response)
    Communication.create_with_twilio_details!(
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
end
