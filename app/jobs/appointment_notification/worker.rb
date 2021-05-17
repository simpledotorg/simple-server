class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  def metrics
    @metrics ||= Metrics.with_object(self)
  end

  def perform(appointment_reminder_id)
    metrics.increment("attempts")
    unless Flipper.enabled?(:notifications)
      metrics.increment("skipped.feature_disabled")
      return
    end
    reminder = Notification.includes(:appointment, :patient).find(appointment_reminder_id)
    communication_type = reminder.next_communication_type
    unless communication_type
      metrics.increment("skipped.previously_communicated")
      return
    end

    unless reminder.status_scheduled?
      metrics.increment("skipped.not_scheduled")
      return
    end

    send_message(reminder, communication_type)
  end

  private

  def send_message(reminder, communication_type)
    notification_service = NotificationService.new

    if communication_type == "missed_visit_whatsapp_reminder"
      notification_service.send_whatsapp(
        reminder.patient.latest_mobile_number,
        reminder.localized_message,
        callback_url
      ).tap do |response|
        metrics.increment("sent.whatsapp")
      end
    else
      notification_service.send_sms(
        reminder.patient.latest_mobile_number,
        reminder.localized_message,
        callback_url
      ).tap do |response|
        metrics.increment("sent.sms")
      end
    end

    return if notification_service.failed?

    ActiveRecord::Base.transaction do
      create_communication(reminder, communication_type, notification_service.response)
      reminder.status_sent!
    end
  end

  def create_communication(reminder, communication_type, response)
    Communication.create_with_twilio_details!(
      appointment: reminder.appointment,
      notification: reminder,
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
