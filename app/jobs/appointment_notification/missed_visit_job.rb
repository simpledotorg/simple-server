class AppointmentNotification::MissedVisitJob
  include Notifiable
  include Sidekiq::Worker

  sidekiq_options queue: 'high'

  def perform(schedule_hour_start, schedule_hour_finish)
    return unless FeatureToggle.enabled?('APPOINTMENT_REMINDERS')

    Organization.where(id: ENV['APPOINTMENT_NOTIFICATION_ORG_IDS'].split(',')).each do |organization|
      appointments = Appointment.includes(facility: { facility_group: :organization }).where(facility: { facility_groups: { organization: organization } })

      schedule_at = schedule_today_or_tomorrow(schedule_hour_start, schedule_hour_finish)
      AppointmentNotificationService.send_after_missed_visit(appointments: appointments, schedule_at: schedule_at)
    end
  end
end
