class AppointmentNotification::MissedVisitJob
  include Sidekiq::Worker

  sidekiq_options queue: 'high'

  def perform
    return unless FeatureToggle.enabled?('APPOINTMENT_REMINDERS')

    Organization.where(id: ENV['APPOINTMENT_NOTIFICATION_ORG_IDS'].split(',')).each do |organization|
      appointments = Appointment.includes(facility: { facility_group: :organization })
                       .where(facility: { facility_groups: { organization: organization } })

      AppointmentNotificationService.send_after_missed_visit(appointments: appointments)
    end
  end
end
