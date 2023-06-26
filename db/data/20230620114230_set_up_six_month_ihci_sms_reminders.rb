# frozen_string_literal: true

class SetUpSixMonthIhciSmsReminders < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 20_000
  FILTERS = {
    "states" => {"include" => ["Tamil Nadu", "Andhra Pradesh", "West Bengal"]}
  }.freeze
  MONTHS = (7..12).map do |month_number|
    month = Date::ABBR_MONTHNAMES[month_number]
    {
      start_time: DateTime.new(2023, month_number, 1).beginning_of_day,
      end_time: DateTime.new(2023, month_number, 1).end_of_month
      current_patients_experiment_name: "Current Patient #{month} 2023",
      stale_patients_experiment_name: "Stale Patient #{month} 2023"
    }
  end

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    MONTHS.map do |month|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: month[:current_patients_experiment_name],
          start_time: month[:start_time],
          end_time: month[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end

      ActiveRecord::Base.transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: month[:stale_patients_experiment_name],
          start_time: month[:start_time],
          end_time: month[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end
    end
  end

  def down
    MONTHS.map do |month|
      Experimentation::Experiment.current_patients.find_by_name(month[:current_patients_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(month[:stale_patients_experiment_name])&.cancel
    end
  end
end
