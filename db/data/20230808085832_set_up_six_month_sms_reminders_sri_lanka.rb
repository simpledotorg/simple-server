# frozen_string_literal: true

class SetUpSixMonthSmsRemindersSriLanka < ActiveRecord::Migration[6.1]
  first_experiment_start_time = DateTime.parse("1 Sep 2023")
  experiment_start_times = (0..5).map do |n|
    first_experiment_start_time + n.months
  end
  EXPERIMENTS_DATA = experiment_start_times.map do |start_time|
    month_name = DateTime::MONTHNAMES[start_time.month]
    year = start_time.year
    {
      name: "Current Patient #{month_name} #{year}",
      start_time: start_time.beginning_of_day,
      end_time: start_time.end_of_month.beginning_of_day
    }
  end

  def up
    return unless CountryConfig.current_country?("Sri Lanka") && SimpleServer.env.production?

    EXPERIMENTS_DATA.map do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_data[:name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: 5000
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "sms_reminders_cascade - #{experiment.name}")
          cascade.reminder_templates.create!(message: "notifications.sri_lanka.one_day_before_appointment", remind_on_in_days: -1)
          cascade.reminder_templates.create!(message: "notifications.sri_lanka.three_days_missed_appointment", remind_on_in_days: 3)
        end
      end
    end
  end

  def down
    EXPERIMENTS_DATA.map do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:name])&.cancel
    end
  end
end
