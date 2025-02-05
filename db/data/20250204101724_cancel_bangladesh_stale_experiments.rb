# frozen_string_literal: true

class CancelBangladeshStaleExperiments < ActiveRecord::Migration[6.1]
  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?
    Experimentation::Experiment.upcoming.where(experiment_type: "stale_patients").each do |experiment|
      experiment.destroy # ...because we need the associated notifications gone too
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
