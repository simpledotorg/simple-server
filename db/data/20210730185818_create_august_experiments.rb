class CreateAugustExperiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India")
    Experimentation::Experiment.update_all(state: :complete)

    Seed::ExperimentSeeder.create_current_experiment(
      experiment_name: "Current Patient August 2021",
      start_time: Time.parse("Aug 5, 2021"),
      end_time: Time.parse("Sep 4, 2021)"
    )
    Seed::ExperimentSeeder.create_stale_experiment(
      experiment_name: "Stale Patient August 2021",
      start_time: Time.parse("Aug 5, 2021"),
      end_time: Time.parse("Sep 4, 2021)"
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
