# frozen_string_literal: true

class ReEnableSmsIndia < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 5000
  # TODO: Replace below states with active states in India.
  FILTERS = {
    "states" => {"include" => ["Maharashtra", "Andhra Pradesh", "West Bengal"]}
  }.freeze
  CANCELLED_EXPERIMENTS_MONTHS = (9..12).map do |month_number|
    Date::ABBR_MONTHNAMES[month_number]
  end

  NEW_EXPERIMENTS_DATA = (11..12).map do |month_number|
    month = Date::ABBR_MONTHNAMES[month_number]
    {
      start_time: DateTime.new(2023, month_number).beginning_of_month,
      end_time: DateTime.new(2023, month_number).end_of_month,
      current_patients_experiment_name: "Current Patient V2 #{month} 2023",
      stale_patients_experiment_name: "Stale Patient V2 #{month} 2023"
    }
  end

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    CANCELLED_EXPERIMENTS_MONTHS.each do |month|
      outdated_current_experiment = Experimentation::CurrentPatientExperiment.find_by_name("Current Patient #{month} 2023")
      outdated_current_experiment.cancel
      outdated_current_experiment.evict_patients

      outdated_stale_experiment = Experimentation::StalePatientExperiment.find_by_name("Stale Patient #{month} 2023")
      outdated_stale_experiment.cancel
      outdated_stale_experiment.evict_patients
    end

    NEW_EXPERIMENTS_DATA.map do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_data[:current_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
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
          name: experiment_data[:stale_patients_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
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
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    NEW_EXPERIMENTS_DATA.map do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_patients_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(experiment_data[:stale_patients_experiment_name])&.cancel
    end
  end
end
