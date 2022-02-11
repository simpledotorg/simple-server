class CreateFebruary2022BdExperiment < ActiveRecord::Migration[5.2]
  def up
    create_current_experiment
    create_stale_experiment
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def create_current_experiment
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.current_patients.create!(
        name: "Current patient experiment February 2022",
        start_time: Date.parse("Feb 12, 2022").beginning_of_day,
        end_time: Date.parse("Mar 14, 2022").end_of_day,
        max_patients_per_day: 5000
      ).tap do |experiment|
        basic_group = experiment.treatment_groups.create!(description: "basic_cascade")
        free_group = experiment.treatment_groups.create!(description: "free_cascade")

        basic_group.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
        basic_group.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
        basic_group.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        free_group.reminder_templates.create!(message: "notifications.set01.free", remind_on_in_days: -1)
        free_group.reminder_templates.create!(message: "notifications.set02.free", remind_on_in_days: 0)
        free_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)
      end
    end
  end

  def create_stale_experiment
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: "Stale patient experiment February 2022",
        start_time: Date.parse("Feb 12, 2022").beginning_of_day,
        end_time: Date.parse("Mar 14, 2022").end_of_day,
        max_patients_per_day: 2000
      ).tap do |experiment|
        single_group = experiment.treatment_groups.create!(description: "single_notification")
        single_group.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)

        cascade_group = experiment.treatment_groups.create!(description: "cascade")
        cascade_group.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        cascade_group.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 1)
        cascade_group.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 4)
      end
    end
  end
end
