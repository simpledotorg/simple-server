class CovidMedicationReminders
  def self.call(number_of_patients: 10_000)
    if CountryConfig.current[:name] != "India" || !SimpleServer.env.production?
      raise "Cannot send Covid medication reminders in this env"
    end

    raise "Experiments are not enabled in this env" unless Flipper.enabled?(:experiment)

    Experimentation::MedicationReminderService.schedule_daily_notifications(patients_per_day: number_of_patients)
    AppointmentNotification::ScheduleExperimentReminders.perform_later
  end
end
