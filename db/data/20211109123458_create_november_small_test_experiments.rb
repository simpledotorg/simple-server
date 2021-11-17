class CreateNovemberSmallTestExperiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    Seed::ExperimentSeeder.create_current_experiment(
      experiment_name: "Small Current Patient November 2021",
      start_time: Date.parse("Nov 10, 2021").beginning_of_day,
      end_time: Date.parse("Nov 11, 2021").end_of_day,
      max_patients_per_day: 100
    )
    Seed::ExperimentSeeder.create_stale_experiment(
      experiment_name: "Small Stale Patient November 2021",
      start_time: Date.parse("Nov 10, 2021").beginning_of_day,
      end_time: Date.parse("Nov 11, 2021").end_of_day,
      max_patients_per_day: 100
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
