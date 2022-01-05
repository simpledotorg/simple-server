class CreateJanuary2022IhciExperiment2 < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    Seed::Experiment2Seeder.create_current_experiment(
      experiment_name: "Current Patient January 2022",
      start_time: Date.parse("Jan 6, 2022").beginning_of_day,
      end_time: Date.parse("Feb 5, 2022").end_of_day,
      max_patients_per_day: 20000
    )
    Seed::Experiment2Seeder.create_stale_experiment(
      experiment_name: "Stale Patient January 2022",
      start_time: Date.parse("Jan 6, 2022").beginning_of_day,
      end_time: Date.parse("Feb 5, 2022").end_of_day,
      max_patients_per_day: 15000
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
