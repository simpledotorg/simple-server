class CreateJun2022IhciCurrentExperiment < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.current_patients.create!(
        name: "Current Patient June 2022",
        start_time: Date.parse("Jun 13, 2022").beginning_of_day,
        end_time: Date.parse("Jun 30, 2022").end_of_day,
        max_patients_per_day: 20000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        triple_group_1 = experiment.treatment_groups.create!(description: "basic_triple_-7_0_3")
        triple_group_1.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -7)
        triple_group_1.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
        triple_group_1.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        triple_group_2 = experiment.treatment_groups.create!(description: "basic_triple_-3_0_1")
        triple_group_2.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -3)
        triple_group_2.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
        triple_group_2.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 1)

        triple_group_3 = experiment.treatment_groups.create!(description: "basic_triple_-3_0_3")
        triple_group_3.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -3)
        triple_group_3.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
        triple_group_3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        triple_group_4 = experiment.treatment_groups.create!(description: "basic_triple_-1_0_3")
        triple_group_4.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
        triple_group_4.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
        triple_group_4.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
