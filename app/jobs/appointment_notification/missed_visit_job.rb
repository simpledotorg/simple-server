class AppointmentNotification::MissedVisitJob < ApplicationJob
  queue_as :high

  def perform
    unless Flipper.enabled?(:notifications)
      logger.info class: self.class.name, msg: "notifications feature is disabled"
      return
    end

    Organization.all.each do |organization|
      MissedVisitReminderService.send_after_missed_visit(appointments: organization.appointments)
    end
  end
end
