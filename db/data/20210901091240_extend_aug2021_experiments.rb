class ExtendAug2021Experiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India")

    experiments = Experimentation::Experiment.where(name: ["Stale Patient August 2021", "Current Patient August 2021"])
    end_date = Date.new(2021, 09, 19)
    experiments.each do |experiment|
      experiment.update!(end_date: end_date)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
