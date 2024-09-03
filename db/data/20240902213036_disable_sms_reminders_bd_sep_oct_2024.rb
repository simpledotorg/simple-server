# frozen_string_literal: true

class DisableSmsRemindersBdSepOct2024 < ActiveRecord::Migration[6.1]
  EXPERIMENTS_TO_CANCEL = %w[Sep Oct].map do |month|
    {
      current_experiment_name: "Current patients #{month} 2024",
      stale_experiment_name: "Stale patients #{month} 2024"
    }
  end

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    EXPERIMENTS_TO_CANCEL.each do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(experiment_data[:stale_experiment_name])&.cancel
    end
  end

  def down
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
    puts "This migration cannot be reversed. To reenable SMSs, create a new migration."
  end
end
