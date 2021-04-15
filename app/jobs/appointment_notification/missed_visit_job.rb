class AppointmentNotification::MissedVisitJob < ApplicationJob
  queue_as :high

  def perform
    return unless FeatureToggle.enabled?("APPOINTMENT_REMINDERS")

    Organization.all.each do |organization|
      AppointmentNotificationService.send_after_missed_visit(appointments: organization.appointments)
    end
  end
end
