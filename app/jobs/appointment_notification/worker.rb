class AppointmentNotification::Worker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(notification_id)
    send_message(Notification.includes(:patient).find(notification_id))
  end

  private

  def send_message(notification)
    if notifiable?(notification)
      NotificationDispatchService.new(notification, appointment_reminder_service).send_message
    end
  end

  def appointment_reminder_service
    CountryConfig.current[:appointment_reminder_service]
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
