class AppointmentNotification::MissedVisitJob
  include Sidekiq::Worker

  sidekiq_options queue: "high"

  def perform
    return unless FeatureToggle.enabled?("APPOINTMENT_REMINDERS")

    enabled_organizations.each do |organization|
      AppointmentNotificationService.send_after_missed_visit(appointments: organization.appointments)
    end
  end

  private

  def enabled_organizations
    Organization.where(id: ENV['APPOINTMENT_NOTIFICATION_ORG_IDS'].split(','))
  end
end
