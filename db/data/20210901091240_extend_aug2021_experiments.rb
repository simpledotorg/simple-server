class ExtendAug2021Experiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India")

    end_date = Date.parse("2021-09-19")

    stale_experiment = Experimentation::Experiment.find_by(name: "Stale Patient August 2021")
    stale_experiment.update!(end_date: end_date)

    # Current patient experiment needs to be updated via runner, since patient selection happens at start, and needs to
    # be "resumed" manually
    Experimentation::Runner.extend_current_patient_experiment(
      name: "Current Patient August 2021",
      end_date: end_date
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
