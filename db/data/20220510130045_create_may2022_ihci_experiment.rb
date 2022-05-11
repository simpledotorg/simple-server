class CreateMay2022IhciExperiment < ActiveRecord::Migration[5.2]
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
        name: "Current Patient May 2022",
        start_time: Date.parse("May 13, 2022").beginning_of_day,
        end_time: Date.parse("Jun 12, 2022").end_of_day,
        max_patients_per_day: 20000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        triple_group_1 = experiment.treatment_groups.create!(description: "basic_triple_-1_0_3")
        triple_group_1.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
        triple_group_1.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)
        triple_group_1.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        triple_group_2 = experiment.treatment_groups.create!(description: "basic_triple_1_3_7")
        triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 1)
        triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 3)
        triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 7)

        double_group_1 = experiment.treatment_groups.create!(description: "basic_double_-1_0")
        double_group_1.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)
        double_group_1.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)

        double_group_2 = experiment.treatment_groups.create!(description: "basic_double_1_3")
        double_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 1)
        double_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 3)

        double_group_3 = experiment.treatment_groups.create!(description: "basic_double_3_7")
        double_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 3)
        double_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 7)

        single_group_1 = experiment.treatment_groups.create!(description: "basic_single_-1")
        single_group_1.reminder_templates.create!(message: "notifications.set01.basic", remind_on_in_days: -1)

        single_group_2 = experiment.treatment_groups.create!(description: "basic_single_0")
        single_group_2.reminder_templates.create!(message: "notifications.set02.basic", remind_on_in_days: 0)

        single_group_3 = experiment.treatment_groups.create!(description: "basic_single_1")
        single_group_3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 1)

        single_group_4 = experiment.treatment_groups.create!(description: "basic_single_3")
        single_group_4.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
      end
    end
  end

  def create_stale_experiment
    transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: "Stale Patient May 2022",
        start_time: Date.parse("May 13, 2022").beginning_of_day,
        end_time: Date.parse("Jun 12, 2022").end_of_day,
        max_patients_per_day: 15000
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        triple_group_1 = experiment.treatment_groups.create!(description: "basic_triple_1_0_7")
        triple_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        triple_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 1)
        triple_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 7)

        triple_group_2 = experiment.treatment_groups.create!(description: "basic_triple_0_1_3")
        triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 1)
        triple_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 3)

        triple_group_3 = experiment.treatment_groups.create!(description: "basic_triple_0_1_2")
        triple_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        triple_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 1)
        triple_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.third", remind_on_in_days: 2)

        double_group_1 = experiment.treatment_groups.create!(description: "basic_double_0_7")
        double_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        double_group_1.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 7)

        double_group_2 = experiment.treatment_groups.create!(description: "basic_double_0_2")
        double_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        double_group_2.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 2)

        double_group_3 = experiment.treatment_groups.create!(description: "basic_double_0_1")
        double_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.first", remind_on_in_days: 0)
        double_group_3.reminder_templates.create!(message: "notifications.set03_basic_repeated.second", remind_on_in_days: 1)

        single_group_3 = experiment.treatment_groups.create!(description: "basic_single_0")
        single_group_3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)
      end
    end
  end
end
