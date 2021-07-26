module Seed
  class ExperimentSeeder
    include ActiveSupport::Benchmarkable

    def self.create_current_experiment(experiment_name: "current patient test experiment")
      experiment = Experimentation::Experiment.create!(name: experiment_name, experiment_type: "current_patients", state: "new")

      _control_group = experiment.treatment_groups.create!(description: "control")

      single_group = experiment.treatment_groups.create!(description: "single_notification")
      single_group.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)

      cascade = experiment.treatment_groups.create!(description: "cascade")
      cascade.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
      cascade.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
      cascade.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
    end

    def self.create_stale_experiment(experiment_name: "stale patient test experiment", start_date:, end_date:)
      experiment = Experimentation::Experiment.create!(
        name: experiment_name,
        experiment_type: "stale_patients",
        state: "new",
        start_date: start_date,
        end_date: end_date
      )

      _control_group = experiment.treatment_groups.create!(description: "control")

      single_group = experiment.treatment_groups.create!(description: "single_notification")
      single_group.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)

      cascade = experiment.treatment_groups.create!(description: "cascade")
      cascade.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
      cascade.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
    end
  end
end
