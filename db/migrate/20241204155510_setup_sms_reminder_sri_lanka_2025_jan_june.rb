# frozen_string_literal: true

class SetupSmsReminderSriLanka2025JanJune < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 5000
  EXPERIMENTS_DATA = %w[Jan Feb Mar Apr May Jun].map do |month|
    {
      start_time: "#{month} 2025".to_datetime.beginning_of_month,
      end_time: "#{month} 2025".to_datetime.end_of_month,
      current_patients_experiment_name: "Current Patient #{month} 2025"
    }
  end

  def up
    return unless CountryConfig.current_country?("Sri Lanka") && SimpleServer.env.production?

    EXPERIMENTS_DATA.each do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_data[:current_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "sms_reminders_cascade - #{experiment_data[:current_patients_experiment_name]}")
          cascade.reminder_templates.create!(message: "notifications.sri_lanka.one_day_before_appointment", remind_on_in_days: -1)
          cascade.reminder_templates.create!(message: "notifications.sri_lanka.three_days_missed_appointment", remind_on_in_days: 3)
        end
      end
    end
  end

  def down
    EXPERIMENTS_DATA.map do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_patients_experiment_name])&.cancel
    end
  end
end
