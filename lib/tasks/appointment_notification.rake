namespace :appointment_notification do
  DEFAULT_TIME_WINDOW_START = 14
  DEFAULT_TIME_WINDOW_FINISH = 16

  desc "Send automatic SMS reminder to patients who missed their scheduled visit by three days"
  task three_days_after_missed_visit: :environment do
    AppointmentNotification::MissedVisitJob
      .perform_async(Config.get_int(
        "APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_START", DEFAULT_TIME_WINDOW_START
      ),
        Config.get_int(
          "APPOINTMENT_NOTIFICATION_HOUR_OF_DAY_FINISH", DEFAULT_TIME_WINDOW_FINISH
        ))
  end
end
