module Seed
  class ExperimentSeeder
    include ActiveSupport::Benchmarkable

    BUCKETS = %w[basic gratitude free alarm emotional_relatives emotional_guilt professional_request response]

    def self.create_current_experiment(experiment_name: "active-test-experiment")
      experiment = Experimentation::Experiment.create!(name: experiment_name, experiment_type: "current_patients", state: "new")

      _control_group = experiment.treatment_groups.create!(description: "control")

      BUCKETS.each do |bucket_name|
        single_group = experiment.treatment_groups.create!(description: "single_notification_#{bucket_name}")
        single_group.reminder_templates.create!(message: "notifications.set01.#{bucket_name}", remind_on_in_days: -1)

        cascade = experiment.treatment_groups.create!(description: "cascade_#{bucket_name}")
        cascade.reminder_templates.create!(message: "notifications.set01.#{bucket_name}", remind_on_in_days: -1)
        cascade.reminder_templates.create!(message: "notifications.set02.#{bucket_name}", remind_on_in_days: 0)
        cascade.reminder_templates.create!(message: "notifications.set03.#{bucket_name}", remind_on_in_days: 3)
      end
    end

    def self.create_stale_experiment(experiment_name: "stale-test-experiment")
      experiment = Experimentation::Experiment.create!(name: experiment_name, experiment_type: "stale_patients", state: "new")

      _control_group = experiment.treatment_groups.create!(description: "control")

      BUCKETS.each do |bucket_name|
        single_group = experiment.treatment_groups.create!(description: "single_notification_#{bucket_name}")
        single_group.reminder_templates.create!(message: "notifications.set01.#{bucket_name}", remind_on_in_days: -1)

        cascade = experiment.treatment_groups.create!(description: "cascade_#{bucket_name}")
        cascade.reminder_templates.create!(message: "notifications.set02.#{bucket_name}", remind_on_in_days: 0)
        cascade.reminder_templates.create!(message: "notifications.set03.#{bucket_name}", remind_on_in_days: 3)
      end
    end
  end
end
