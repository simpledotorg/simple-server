class AppointmentNotification::MissedVisitJob
  include Notifiable
  include Sidekiq::Worker

  sidekiq_options unique_across_workers: true,
                  queue: 'default',
                  lock_expiration: 1.day.to_i

  def perform(user, schedule_hour_start, schedule_hour_finish)
    AppointmentNotificationService
      .new(user)
      .send_after_missed_visit(schedule_at: schedule_now_or_later(schedule_hour_start, schedule_hour_finish))
  end
end
