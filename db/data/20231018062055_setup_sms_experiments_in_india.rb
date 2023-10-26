# frozen_string_literal: true

class SetupSmsExperimentsInIndia < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 5000
  WB_NG_STATE_FILTERS = {"states" => {"include" => ["West Bengal", "Nagaland"]}}.freeze
  CHENNAI_DISTRICT_FILTERS = {"blocks" => {"include" => [
    "1b9a09fd-32e8-4f8a-a471-782b9bf29ebf", "2027b7af-10b1-43ec-93b3-8796e4cd5b8c", "2706f19c-2eac-478c-8a09-3028df1a533e", "2fb1ad1a-024a-4e6b-b49f-b1eb22db9755", "37164885-56cd-47e8-a8b5-d616cef8b06f", "47991521-7d4e-49bb-b9b5-abcee1096aae", "4a6fadd3-f96b-436f-b4e1-57a9dc2ca2b6", "603a6001-d79d-4e90-a80c-bd9b2341d5b1", "883e24b8-39d8-4e04-ab75-401d8f5220a9", "9265f5a3-636a-43b0-8375-a2aebb4c6a89", "adcd4458-4bf4-4d04-a591-2ed3ebdc5dce", "af0a2b3c-a605-4607-a15a-787a1be7e8f3", "b51bdc8a-4e89-48d6-8e8e-dbf331502a3f", "c7acfa83-94c8-4943-a59d-9f13ad500151", "fd4b4f4c-e2e8-4f17-9637-1f5943d04279"
  ]}}.freeze
  PUNE_DISTRICT_FILTERS = {"blocks" => {"include" => [
    # Blocks inside pimpri-chinchwad-municipal-corporation district
    "2e914f1b-c9a2-4d25-8640-064e0cd3ce0e", "32bf53b1-cc62-44f0-a9ac-023b37eaf330", "3b3311c4-74bc-418f-885c-eee212781fc8", "4c978ae7-5fbd-4d30-af75-13cfaf557537", "58e10ec5-7f87-427d-ba82-9ead9ac111c6", "636cd865-8156-4e7e-80f0-05578cfdb77c", "940346fc-5909-4e6a-962a-54b69961eeed", "b6dfb375-aa9c-4f94-bd61-96caf0c40dd7", "efdd301b-890b-4011-a514-fcefb186e0cc",
    # Blocks inside pune-municipal-corporation district
    "ab873118-625a-403c-b679-ffcd8380815c", "cb80c788-be64-4b92-8018-b30c5d9fcc0f", "d52814ee-1507-44ca-b0fe-6835a9b1d052", "e5594859-e114-4900-bda3-09e73b5bae24", "f3afb747-e21c-456c-88f9-e4960ea97748"
  ]}}.freeze

  CANCELLED_EXPERIMENTS_MONTHS = (9..12).map do |month_number|
    Date::ABBR_MONTHNAMES[month_number]
  end

  NEW_EXPERIMENTS_DATA = (11..12).map do |month_number|
    month = Date::ABBR_MONTHNAMES[month_number]
    {
      start_time: DateTime.new(2023, month_number).beginning_of_month,
      end_time: DateTime.new(2023, month_number).end_of_month,
      month: month
    }
  end

  private def create_experiments(name, start_time, end_time, filters)
    ActiveRecord::Base.transaction do
      Experimentation::Experiment.current_patients.create!(
        name: "Current #{name}",
        start_time: start_time,
        end_time: end_time,
        max_patients_per_day: PATIENTS_PER_DAY,
        filters: filters
      ).tap do |experiment|
        cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
        cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 3)
        cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
      end
    end

    ActiveRecord::Base.transaction do
      Experimentation::Experiment.stale_patients.create!(
        name: "Stale #{name}",
        start_time: start_time,
        end_time: end_time,
        max_patients_per_day: PATIENTS_PER_DAY,
        filters: filters
      ).tap do |experiment|
        cascade = experiment.treatment_groups.create!(description: "official_short_cascade")
        cascade.reminder_templates.create!(message: "notifications.set02.official_short", remind_on_in_days: 0)
        cascade.reminder_templates.create!(message: "notifications.set03.official_short", remind_on_in_days: 7)
      end
    end
  end

  def up
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    CANCELLED_EXPERIMENTS_MONTHS.each do |month|
      outdated_current_experiment = Experimentation::CurrentPatientExperiment.find_by_name("Current Patient #{month} 2023")
      outdated_current_experiment.cancel
      outdated_current_experiment.evict_patients

      outdated_stale_experiment = Experimentation::StalePatientExperiment.find_by_name("Stale Patient #{month} 2023")
      outdated_stale_experiment.cancel
      outdated_stale_experiment.evict_patients
    end

    NEW_EXPERIMENTS_DATA.map do |experiment_data|
      start_time = experiment_data[:start_time]
      end_time = experiment_data[:end_time]
      month = experiment_data[:month]
      wb_ng_experiment_name = "Patient WB/NG #{month} 2023"
      chennai_experiment_name = "Patient Chennai #{month} 2023"
      pune_experiment_name = "Patient Pune #{month} 2023"

      create_experiments(wb_ng_experiment_name, start_time, end_time, WB_NG_STATE_FILTERS)
      create_experiments(chennai_experiment_name, start_time, end_time, CHENNAI_DISTRICT_FILTERS)
      create_experiments(pune_experiment_name, start_time, end_time, PUNE_DISTRICT_FILTERS)
    end
  end

  private def cancel_experiments(name)
    Experimentation::Experiment.current_patients.find_by_name("Current #{name}")&.cancel
    Experimentation::Experiment.stale_patients.find_by_name("Stale #{name}")&.cancel
  end

  def down
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    NEW_EXPERIMENTS_DATA.map do |experiment_data|
      month = experiment_data[:month]
      cancel_experiments("Patient WB/NG #{month} 2023")
      cancel_experiments("Patient Chennai #{month} 2023")
      cancel_experiments("Patient Pune #{month} 2023")
    end
  end
end
