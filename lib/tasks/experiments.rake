namespace :experiments do
  desc "Conduct an experiment for the day and send out notifications"
  task conduct_daily: :environment do
    unless CountryConfig.current_country?("India")
      Time.use_zone(CountryConfig.current[:time_zone]) do
        Experimentation::Runner.call
        AppointmentNotification::ScheduleExperimentReminders.call
      end
    end
  end
end
