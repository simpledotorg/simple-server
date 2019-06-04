class AppointmentNotification::MissedVisitJob
  include Notifiable
  include Sidekiq::Worker

  def perform(user_id, schedule_hour_start, schedule_hour_finish)
    return unless FeatureToggle.enabled?('SMS_REMINDERS')

    AppointmentNotificationService
      .new(User.find(user_id))
      .send_after_missed_visit(schedule_at:
                                 schedule_now_or_tomorrow(schedule_hour_start, schedule_hour_finish))
  end
end
