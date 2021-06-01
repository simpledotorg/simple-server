class CovidMedicationReminders
  def self.call(number_of_patients: 10_000)
    if CountryConfig.current[:name] != "India" || !SimpleServer.env.production? || !Flipper.enabled?(:experiment)
      raise "Cannot send Covid medication reminders in this env"
    end

    Experimentation::MedicationReminderService.schedule_daily_notifications(patients_per_day: number_of_patients)
    AppointmentNotification::ScheduleExperimentReminders.perform_later
  end
end
