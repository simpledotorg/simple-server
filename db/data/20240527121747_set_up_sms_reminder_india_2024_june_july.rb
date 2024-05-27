# frozen_string_literal: true

class SetUpSmsRemindersIndiaJuneJuly2024 < ActiveRecord::Migration[6.1]
  INCLUDED_FACILITY_SLUG = [
    Facility.where(district: "Chennai").pluck(:slug),
    Facility.where(state: "West Bengal").pluck(:slug)
  ].flatten

  # Regions where Simple is active and we send sms reminders currently:
  # States - All of West Bengal, selcted districts in Tamil Nadu
  # Districts - Chennai
  REGION_FILTERS = {"facilities" => {"include" => INCLUDED_FACILITY_SLUG}}
  PATIENTS_PER_DAY = 20_000
  EXPERIMENTS_DATA = (6..7).map do |month_number|
    month = Date::ABBR_MONTHNAMES[month_number]
    {
      start_time: DateTime.new(2024, month_number).beginning_of_month,
      end_time: DateTime.new(2024, month_number).end_of_month,
      current_patients_experiment_name: "Current Patient #{month} 2024",
      stale_patients_experiment_name: "Stale Patient #{month} 2024"
    }
  end

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    EXPERIMENTS_DATA.each do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_data[:current_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end

      ActiveRecord::Base.transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: experiment_data[:stale_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
          cascade.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
          cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
        end
      end
    end
  end

  def down
    EXPERIMENTS_DATA.map do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_patients_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(experiment_data[:stale_patients_experiment_name])&.cancel
    end
  end
end
