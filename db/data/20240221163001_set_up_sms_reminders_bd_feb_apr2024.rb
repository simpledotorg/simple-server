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
  EXCLUDED_BLOCK_REGION_IDS = %w[0cb0aedb-af67-459e-a579-bf5239876812 a5df21ba-e739-4dbe-8b87-3341940fd17d 047734c1-fc8c-4aa7-8144-cd4e75a09829
    3d62c4c3-af05-4c11-836f-ea04cf896f47 9be73767-7743-4d66-a1dd-e70abf8331bf 085a9ec5-d8cf-4779-9faf-963e8a54bb09
    db9c41cc-d248-42c7-98c9-a121f450182a 649bf02e-0d87-4b99-b18d-77ea9b3d040c c311439b-1a64-48fa-89ca-dd4306954a6e
    7d4a3a15-82c9-465a-9aa0-848af7804e51 0456335e-6e20-4676-8b5b-e31731ee0e99 d8ec2578-000c-4c72-8954-07516858bf40
    5f0aabdd-2613-4ccc-a9bc-2351b2100c9b 2880719d-1d9f-4f4a-9c89-b6cec7c2fe21 da8389a3-fd33-498a-9878-efc2a7719fe5
    1714c5f4-68fb-472f-89df-2af3697400d1 d9110284-2d82-4b02-af57-99ab193ea875 7b783a01-9776-4a97-924c-fb4d98fa207a
    9ad41707-5535-47c5-99ed-5b8b5966a0f5 03d8774c-d95d-4bf1-9e0f-8f60c1cf367a 568bfdd5-fd94-46c3-9664-f4a88744902b
    d76a2019-e84d-44eb-8787-b7fad9240968].freeze
  REGION_FILTERS = {
    "states" => {"include" => ["Sylhet", "Chattogram", "Barishal", "Rajshahi", "Mymensingh"]},
    "blocks" => {"exclude" => EXCLUDED_BLOCK_REGION_IDS}
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
