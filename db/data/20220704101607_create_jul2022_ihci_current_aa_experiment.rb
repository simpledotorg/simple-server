class CreateJul2022IhciCurrentAaExperiment < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    Experimentation::Experiment.current_patients.create!(
      name: "A/A Current Patient July 2022",
      start_time: Date.parse("Jul 5, 2022").beginning_of_day,
      end_time: Date.parse("Jul 10, 2022").end_of_day,
      max_patients_per_day: 20000
    ).tap do |experiment|
      _control_group = experiment.treatment_groups.create!(description: "control")

      double_group_1 = experiment.treatment_groups.create!(description: "basic_double_3_7-I")
      double_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 3)
      double_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 7)

      double_group_2 = experiment.treatment_groups.create!(description: "basic_double_3_7-II")
      double_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 3)
      double_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 7)

      triple_group_1 = experiment.treatment_groups.create!(description: "basic_triple_1_3_7-I")
      triple_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 1)
      triple_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 3)
      triple_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 7)

      triple_group_2 = experiment.treatment_groups.create!(description: "basic_triple_1_3_7-II")
      triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 1)
      triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 3)
      triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 7)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
