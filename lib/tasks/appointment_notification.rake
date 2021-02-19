namespace :appointment_notification do
  desc "Send automatic SMS reminder to patients who missed their scheduled visit by three days"
  task three_days_after_missed_visit: :environment do
    AppointmentNotification::MissedVisitJob.perform_later
  end
end
