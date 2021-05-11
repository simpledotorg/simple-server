class AppointmentNotification::Worker
  include Rails.application.routes.url_helpers
  include Sidekiq::Worker

  sidekiq_options queue: :high

  DEFAULT_LOCALE = :en
  
  def metrics
    @metrics ||= Metrics.with_object(self)
  end

  def perform(appointment_reminder_id, communication_type)
    metrics.increment("attempts")
    unless Flipper.enabled?(:appointment_reminders)
      metrics.increment("skipped.feature_disabled")
      return
    end
    reminder = AppointmentReminder.includes(:appointment, :patient).find(appointment_reminder_id)
    if reminder.appointment.previously_communicated_via?(communication_type)
      metrics.increment("skipped.previously_communicated")
      return
    end
    if reminder.status != "scheduled"
      report_error("scheduled appointment reminder has invalid status")
      return
    end
    send_message(reminder, communication_type)
  end

  private

  def send_message(reminder, communication_type)
    notification_service = NotificationService.new

    begin
      response = if communication_type == "missed_visit_whatsapp_reminder"
        notification_service.send_whatsapp(
          reminder.patient.latest_mobile_number,
          appointment_message(reminder),
          callback_url
        ).tap do |response|
          metrics.increment("sent.whatsapp")
        end
      else
        notification_service.send_sms(
          reminder.patient.latest_mobile_number,
          appointment_message(reminder),
          callback_url
        ).tap do |response|
          metrics.increment("sent.sms")
        end
      end
      ActiveRecord::Base.transaction do
        create_communication(reminder, communication_type, response)
        reminder.status_sent!
      end
    rescue Twilio::REST::TwilioError => e
      metrics.increment(:error)
      report_error(e)
    end
  end

  def create_communication(reminder, communication_type, response)
    Communication.create_with_twilio_details!(
      appointment: reminder.appointment,
      appointment_reminder: reminder,
      twilio_sid: response.sid,
      twilio_msg_status: response.status,
      communication_type: communication_type
    )
  end

  def appointment_message(reminder)
    I18n.t(
      reminder.message,
      facility_name: reminder.appointment.facility.name,
      locale: patient_locale(reminder.patient)
    )
  end

  def patient_locale(patient)
    patient.address&.locale || DEFAULT_LOCALE
  end

  def callback_url
    api_v3_twilio_sms_delivery_url(
      host: ENV.fetch("SIMPLE_SERVER_HOST"),
      protocol: ENV.fetch("SIMPLE_SERVER_HOST_PROTOCOL")
    )
  end

  def report_error(e)
    Sentry.capture_message("Error while processing appointment notifications",
      extra: {
        exception: e.to_s
      },
      tags: {
        type: "appointment-notification-job"
      })
  end
end
