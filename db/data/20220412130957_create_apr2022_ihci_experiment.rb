class CreateApr2022IhciExperiment < ActiveRecord::Migration[5.2]
  REMINDERS = %w[basic gratitude free alarm emotional_relatives emotional_guilt professional_request]

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
        name: "Current Patient April 2022",
        start_time: Date.parse("Apr 12, 2022").beginning_of_day,
        end_time: Date.parse("May 12, 2022").end_of_day,
        max_patients_per_day: 20000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        REMINDERS.each do |reminder|
          group = experiment.treatment_groups.create!(description: "#{reminder}_cascade")
          group.reminder_templates.create!(message: "notifications.set01.#{reminder}", remind_on_in_days: -1)
          group.reminder_templates.create!(message: "notifications.set02.#{reminder}", remind_on_in_days: 0)
          group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 3)
        end
      end
    end
  end

  def create_stale_experiment
    transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: "Stale Patient April 2022",
        start_time: Date.parse("Apr 12, 2022").beginning_of_day,
        end_time: Date.parse("May 12, 2022").end_of_day,
        max_patients_per_day: 15000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        REMINDERS.each do |reminder|
          group = experiment.treatment_groups.create!(description: "#{reminder}_single_notification")
          group.reminder_templates.create!(message: "notifications.set03.#{reminder}", remind_on_in_days: 0)
        end
      end
    end
  end
end
