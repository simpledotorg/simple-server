class CreateMedicationReminderExperiment < ActiveRecord::Migration[5.2]
  def up
    if CountryConfig.current_country?("India")
      experiment = Experimentation::Experiment.create!(name: "covid medication reminders", experiment_type: "medication_reminder", state: "new")
      treatment_group = experiment.treatment_groups.create!(description: "one-off message")
      treatment_group.reminder_templates.create!(message: "notifications.covid.medication_reminder", remind_on_in_days: 0)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
