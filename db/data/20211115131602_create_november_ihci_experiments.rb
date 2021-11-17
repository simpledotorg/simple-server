class CreateNovemberIhciExperiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    Seed::ExperimentSeeder.create_current_experiment(
      experiment_name: "Current Patient November 2021",
      start_time: Date.parse("Nov 16, 2021").beginning_of_day,
      end_time: Date.parse("Dec 15, 2021").end_of_day,
      max_patients_per_day: 9000
    )
    Seed::ExperimentSeeder.create_stale_experiment(
      experiment_name: "Stale Patient November 2021",
      start_time: Date.parse("Nov 16, 2021").beginning_of_day,
      end_time: Date.parse("Dec 15, 2021").end_of_day,
      max_patients_per_day: 6000
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
