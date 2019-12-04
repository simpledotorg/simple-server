class AppointmentNotification::MissedVisitJob
  include Notifiable
  include Sidekiq::Worker

  sidekiq_options queue: 'high'

  def perform(schedule_hour_start, schedule_hour_finish)
    return unless FeatureToggle.enabled?('SMS_REMINDERS')

    AppointmentNotificationService
      .new
      .send_after_missed_visit(schedule_at:
                                 schedule_today_or_tomorrow(schedule_hour_start, schedule_hour_finish))
  end
end
