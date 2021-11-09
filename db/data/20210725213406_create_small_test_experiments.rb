class CreateSmallTestExperiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    Seed::ExperimentSeeder.create_current_experiment(
      experiment_name: "Small Current Patient July 2021",
      start_time: Time.parse("Jul 28, 2021"),
      end_time: Time.parse("Jul 30, 2021"),
      max_patients_per_day: 100
    )
    Seed::ExperimentSeeder.create_stale_experiment(
      experiment_name: "Small Stale Patient July 2021",
      start_time: Time.parse("Jul 28, 2021"),
      end_time: Time.parse("Jul 30, 2021"),
      max_patients_per_day: 100
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
