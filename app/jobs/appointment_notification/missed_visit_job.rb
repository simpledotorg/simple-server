class AppointmentNotification::MissedVisitJob
  include Notifiable
  include Sidekiq::Worker

  sidekiq_options unique_across_workers: true,
                  queue: 'default',
                  lock_expiration: 1.day.to_i

  def perform(user_id, schedule_hour_start, schedule_hour_finish)
    if FeatureToggle.enabled?('SMS_REMINDERS')
      AppointmentNotificationService
        .new(User.find(user_id))
        .send_after_missed_visit(schedule_at:
                                   schedule_now_or_later(schedule_hour_start, schedule_hour_finish))
    end
  end
end
