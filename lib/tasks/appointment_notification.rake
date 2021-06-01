namespace :appointment_notification do
  desc "Send automatic SMS reminder to patients who missed their scheduled visit by three days"
  task three_days_after_missed_visit: :environment do
    AppointmentNotification::MissedVisitJob.perform_later
  end

  desc "Schedule one time COVID medication reminders for next communication window"
  task :covid_medication_reminders, [:number_of_patients] => :environment do |_t, args|
    CovidMedicationReminders.call(number_of_patients: args[:number_of_patients]&.to_i)
  end
end
