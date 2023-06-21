# frozen_string_literal: true

class SetUpSixMonthIhciSmsReminders < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 20000
  FILTERS = {
    "states" => {"include" => ["Tamil Nadu, Andhra Pradesh, West Bengal"]}
  }.freeze
  months = (7..12).to_a
  MONTHS = months.to_h do |month|
    month_name = Date::ABBR_MONTHNAMES[month]
    [
      month_name,
      {
        start_time: DateTime.new(2023, month, 1).beginning_of_day,
        end_time: DateTime.new(2023, month, 1).next_month.prev_day,
        current_patients_experiment_name: "Current Patient #{month_name} 2023",
        stale_patients_experiment_name: "Stale Patient #{month_name} 2023"
      }
    ]
  end

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    MONTHS.map do |_name, metadata|
      transaction do
        Experimentation::Experiment.current_patients.create!(
          name: metadata[:current_patients_experiment_name],
          start_time: metadata[:start_time],
          end_time: metadata[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end

      transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: metadata[:stale_patients_experiment_name],
          start_time: metadata[:start_time],
          end_time: metadata[:end_time],
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
    MONTHS.map do |_name, metadata|
      Experimentation::Experiment.current_patients.find_by_name(metadata[:current_patients_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(metadata[:stale_patients_experiment_name])&.cancel
    end
  end
end
