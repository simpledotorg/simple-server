class AppointmentNotification::MissedVisitJob < ApplicationJob
  queue_as :high

  def perform
    return unless Flipper.enabled?(:appointment_reminders)

    Organization.all.each do |organization|
      AppointmentNotificationService.send_after_missed_visit(appointments: organization.appointments)
    end
  end
end
