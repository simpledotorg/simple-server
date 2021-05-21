class AppointmentNotification::MissedVisitJob < ApplicationJob
  queue_as :high

  def perform
    unless Flipper.enabled?(:notifications)
      logger.info class: self.class.name, msg: "notifications feature is disabled"
      return
    end

    eligible_appointments = Appointment.eligible_for_reminders(days_overdue: 3)
    AppointmentNotificationService.send_after_missed_visit(eligible_appointments)
  end
end
