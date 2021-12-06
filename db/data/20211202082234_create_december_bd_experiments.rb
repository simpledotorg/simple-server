class CreateDecemberBdExperiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    Seed::ExperimentSeeder.create_current_experiment(
      experiment_name: "Current Patient December 2021",
      start_time: Date.parse("Dec 7, 2021").beginning_of_day,
      end_time: Date.parse("Jan 6, 2022").end_of_day,
      max_patients_per_day: 5000
    )
    Seed::ExperimentSeeder.create_stale_experiment(
      experiment_name: "Stale Patient December 2021",
      start_time: Date.parse("Dec 7, 2021").beginning_of_day,
      end_time: Date.parse("Jan 6, 2022").end_of_day,
      max_patients_per_day: 2000
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
