class CreateJanuary2022IhciExperiment < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    Seed::Experiment2Seeder.create_current_experiment(
        experiment_name: "Current Patient January 2022",
        start_time: Date.parse("Jan 3, 2022").beginning_of_day,
        end_time: Date.parse("Feb 2, 2022").end_of_day,
        max_patients_per_day: 9000
      )
      Seed::Experiment2Seeder.create_stale_experiment(
        experiment_name: "Stale Patient January 2022",
        start_time: Date.parse("Jan 3, 2021").beginning_of_day,
        end_time: Date.parse("Feb 2, 2021").end_of_day,
        max_patients_per_day: 6000
      )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
