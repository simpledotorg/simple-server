class SetUpSmsRemindersBdFebApr2024 < ActiveRecord::Migration[6.1]
  EXPERIMENTS_DATA = (2..4).map do |month_number|
    month = Date::ABBR_MONTHNAMES[month_number]
    {
      current_experiment_name: "Current patients #{month} 2024",
      stale_experiment_name: "Stale patients #{month} 2024",
      start_time: DateTime.new(2024, month_number).beginning_of_month,
      end_time: DateTime.new(2024, month_number).end_of_month
    }
  end
  MAX_PATIENTS_PER_DAY = 5000
  REGION_FILTERS = {
    "districts" => {"include" => ["Sylhet", "Moulvibazar", "Habiganj", "Sunamganj", "Barishal", "Jhalokathi", " Feni",
      "Chattogram", "Bandarban", "Pabna", "Rajshahi", "Sirajganj", "Sherpur", "Jamalpur"]}
  }.freeze

  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    EXPERIMENTS_DATA.each do |experiment_data|
      ActiveRecord::Base.transaction do
        Experimentation::Experiment.current_patients.create!(
          name: experiment_data[:current_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: MAX_PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          treatment_group = experiment.treatment_groups.create!(description: "cascade_free")
          treatment_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 1)
          treatment_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)
        end
      end

      ActiveRecord::Base.transaction do
        Experimentation::Experiment.stale_patients.create!(
          name: experiment_data[:stale_experiment_name],
          start_time: experiment_data[:start_time],
          end_time: experiment_data[:end_time],
          max_patients_per_day: MAX_PATIENTS_PER_DAY,
          filters: REGION_FILTERS
        ).tap do |experiment|
          treatment_group = experiment.treatment_groups.create!(description: "cascade_free")
          treatment_group.reminder_templates.create!(message: "notifications.set02.free", remind_on_in_days: 0)
          treatment_group.reminder_templates.create!(message: "notifications.set03.free", remind_on_in_days: 3)
        end
      end
    end
  end

  def down
    EXPERIMENTS_DATA.each do |experiment_data|
      Experimentation::Experiment.current_patients.find_by_name(experiment_data[:current_experiment_name])&.cancel
      Experimentation::Experiment.stale_patients.find_by_name(experiment_data[:stale_experiment_name])&.cancel
    end
  end
end
