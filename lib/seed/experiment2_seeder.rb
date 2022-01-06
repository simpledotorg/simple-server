# frozen_string_literal: true

module Seed
  class Experiment2Seeder
    include ActiveSupport::Benchmarkable

    REMINDERS = %w[basic gratitude free alarm emotional_relatives emotional_guilt professional_request]

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

          REMINDERS.each do |reminder|
            group = experiment.treatment_groups.create!(description: "#{reminder}_cascade")
            group.reminder_templates.create!(message: "notifications.set01.#{reminder}", remind_on_in_days: -1)
            group.reminder_templates.create!(message: "notifications.set02.#{reminder}", remind_on_in_days: 0)
            group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 3)
          end
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

          REMINDERS.each do |reminder|
            group = experiment.treatment_groups.create!(description: "#{reminder}_single_notification")
            group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 0)
          end
        end
      end
    end
  end
end
