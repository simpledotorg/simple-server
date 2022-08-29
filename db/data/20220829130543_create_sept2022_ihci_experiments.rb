class CreateSept2022IhciExperiments < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    create_current_experiment
    create_stale_experiment
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def create_current_experiment
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.current_patients.create!(
        name: "Current Patient Sept 2022 Basic Variations",
        start_time: Date.parse("30 Aug 2022").beginning_of_day,
        end_time: Date.parse("29 Sep 2022").end_of_day,
        max_patients_per_day: 20_000
      ).tap do |experiment|
        group = experiment.treatment_groups.create!(description: "official_short_cascade")
        group.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
        group.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
      end
    end
  end

  def create_stale_experiment
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: "Stale Patient Sept 2022 Basic Variations",
        start_time: Date.parse("30 Aug 2022").beginning_of_day,
        end_time: Date.parse("29 Sep 2022").end_of_day,
        max_patients_per_day: 20_000
      ).tap do |experiment|
        group = experiment.treatment_groups.create!(description: "official_short_cascade")
        group.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
        group.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
      end
    end
  end
end
