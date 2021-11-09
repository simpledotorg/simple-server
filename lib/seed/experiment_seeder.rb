module Seed
  class ExperimentSeeder
    include ActiveSupport::Benchmarkable

    class << self
      delegate :transaction, to: ActiveRecord::Base
    end

    def self.create_current_experiment(start_time:, end_time:, experiment_name:, max_patients_per_day:)
      transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_name,
          start_time: start_time,
          end_time: end_time,
          max_patients_per_day: max_patients_per_day
        ).tap do |experiment|
          _control_group = experiment.treatment_groups.create!(description: "control")

          single_group = experiment.treatment_groups.create!(description: "single_notification")
          single_group.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)

          cascade = experiment.treatment_groups.create!(description: "cascade")
          cascade.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
          cascade.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
          cascade.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
        end
      end
    end

    def self.create_stale_experiment(start_time:, end_time:, max_patients_per_day:, experiment_name:)
      transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: experiment_name,
          start_time: start_time,
          end_time: end_time,
          max_patients_per_day: max_patients_per_day
        ).tap do |experiment|
          _control_group = experiment.treatment_groups.create!(description: "control")

          single_group = experiment.treatment_groups.create!(description: "single_notification")
          single_group.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)
        end
      end
    end
  end
end
