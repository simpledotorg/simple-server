class CreateJul2022IhciBasicVariationExperiments < ActiveRecord::Migration[5.2]
  REMINDERS = %w[short short_medicines you_must no_date
                 official_short official_short_medicines official_you_must official_no_date]

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    create_current_patients
    create_stale_patients
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def create_current_patients
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.current_patients.create!(
        name: "Current Patient July 2022 Basic Variations",
        start_time: Date.parse("23 Jul 2022").beginning_of_day,
        end_time: Date.parse("22 Aug 2022").end_of_day,
        max_patients_per_day: 20_000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        REMINDERS.each do |reminder|
          group = experiment.treatment_groups.create!(description: "#{reminder}_cascade")
          group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 3)
          group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 7)
        end
      end
    end
  end

  def create_stale_patients
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: "Stale Patient July 2022 Basic Variations",
        start_time: Date.parse("23 Jul 2022").beginning_of_day,
        end_time: Date.parse("22 Aug 2022").end_of_day,
        max_patients_per_day: 20_000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        REMINDERS.each do |reminder|
          group = experiment.treatment_groups.create!(description: "#{reminder}_cascade")
          group.reminder_templates.create!(message: "notifications.set02.#{reminder}", remind_on_in_days: 0)
          group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 7)
        end
      end
    end
  end
end
