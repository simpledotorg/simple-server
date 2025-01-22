# frozen_string_literal: true

class SetupBdh12025SmsSchedule < ActiveRecord::Migration[6.1]
  EXPERIMENTS_DATA = %w[Jan Feb Mar Apr May Jun].map do |month|
    {
      current_experiment_name: "Current patients #{month} 2025",
      stale_experiment_name: "Stale patients #{month} 2025",
      start_time: "#{month} 2025".to_datetime.beginning_of_month,
      end_time: "#{month} 2025".to_datetime.end_of_month
    }
  end

  MAX_PATIENTS_PER_DAY = 5000

  INCLUDED_FACILITY_SLUG = Facility
    .where(facility_type: "UHC")
    .where.not(slug: [
      "uhc-fatikchori",
      "uhc-parsuram",
      "uhc-daganbhuiya"
    ])
    .pluck(:slug)

  REGION_FILTERS = {
    "facilities" => {"include" => INCLUDED_FACILITY_SLUG}
  }.freeze

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
    EXPERIMENTS_DATA.each do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: (experiment_data[:current_experiment_name]).to_s,
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: MAX_PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          treatment_group = experiment.treatment_groups.create!(description: "cascade_free")
          treatment_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 1)
          treatment_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)
        end
      end

      ActiveRecord::Base.transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: (experiment_data[:stale_experiment_name]).to_s,
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: MAX_PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          treatment_group = experiment.treatment_groups.create!(description: "cascade_free")
          treatment_group.reminder_templates.create!(message: "notifications.set02.free", remind_on_in_days: 0)
          treatment_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)
        end
      end
    end
  end

  def down
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
    EXPERIMENTS_DATA.each do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(experiment_data[:stale_experiment_name])&.cancel
    end
  end
end
