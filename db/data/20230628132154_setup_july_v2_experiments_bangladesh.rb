class SetupJulyV2ExperimentsBangladesh < ActiveRecord::Migration[6.1]
  START_TIME = DateTime.new(2023, 7, 1).beginning_of_day
  END_TIME = DateTime.new(2023, 8, 1).beginning_of_day
  CURRENT_PATIENTS_EXPERIMENT = "Current Patient July V2 2023"
  STALE_PATIENTS_EXPERIMENT = "Stale Patient July V2 2023"
  PATIENTS_PER_DAY = 5000
  FILTERS = {
    "states" => {"include" => ["Sylhet"]},
    "facilities" => {"exclude" => ["edaf3ebd-3dbd-48c3-9911-875ad1356f5d", "fe48375c-7826-41dd-9110-d716a9181e8f", "032b5549-eb26-4784-b3c2-162011297df6", "4d1e7df5-edcd-439c-a6c0-86078c9b7c50", "68603a37-175d-4f11-bd30-85fc6c4c3a38", "00db147c-5289-40b4-bd3c-090cac07c9ea", "0fad3822-9f5a-46ea-b02f-90501a184252", "130be963-f38e-4c58-b671-69b71949dfbd", "3d9e19a2-8a57-4248-98fe-e90967806f27", "8bf07061-0681-4224-af29-f265baaf6437"]}
  }

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    buggy_current_experiment = Experimentation::CurrentPatientExperiment.find_by_name("Current Patient July 2023")
    buggy_current_experiment.cancel
    buggy_current_experiment.evict_patients

    buggy_stale_experiment = Experimentation::StalePatientExperiment.find_by_name("Stale Patient July 2023")
    buggy_stale_experiment.cancel
    buggy_stale_experiment.evict_patients

    transaction do
      Experimentation::Experiment.current_patients.create!(
        name: CURRENT_PATIENTS_EXPERIMENT,
        start_time: START_TIME,
        end_time: END_TIME,
        max_patients_per_day: PATIENTS_PER_DAY,
        filters: FILTERS
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        single_group = experiment.treatment_groups.create!(description: "single_notification")
        single_group.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        cascade1 = experiment.treatment_groups.create!(description: "cascade1")
        cascade1.reminder_templates.create!(message: "notifications.set01.official_short", remind_on_in_days: -1)
        cascade1.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
        cascade1.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        cascade2 = experiment.treatment_groups.create!(description: "cascade2")
        cascade2.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 1)
        cascade2.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)

        cascade3 = experiment.treatment_groups.create!(description: "cascade3")
        cascade3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
        cascade3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 7)
      end
    end

    transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: STALE_PATIENTS_EXPERIMENT,
        start_time: START_TIME,
        end_time: END_TIME,
        max_patients_per_day: PATIENTS_PER_DAY,
        filters: FILTERS
      ).tap do |experiment|
        _control_group = experiment.treatment_groups.create!(description: "control")

        single_group = experiment.treatment_groups.create!(description: "single_notification")
        single_group.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)

        cascade1 = experiment.treatment_groups.create!(description: "cascade1")
        cascade1.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)
        cascade1.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
        # Stale (5 buckets): control, 0,  0/3, 0/7, and 0/3/7

        cascade2 = experiment.treatment_groups.create!(description: "cascade2")
        cascade2.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)
        cascade2.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 7)

        cascade3 = experiment.treatment_groups.create!(description: "cascade3")
        cascade3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 0)
        cascade3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 3)
        cascade3.reminder_templates.create!(message: "notifications.set03.basic", remind_on_in_days: 7)
      end
    end
  end

  def down
    Experimentation::Experiment.current_patients.find_by_name(CURRENT_PATIENTS_EXPERIMENT).cancel
    Experimentation::Experiment.stale_patients.find_by_name(STALE_PATIENTS_EXPERIMENT).cancel
  end
  def down
    EXPERIMENTS_DATA.map do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:name])&.cancel
    end
  end
end
