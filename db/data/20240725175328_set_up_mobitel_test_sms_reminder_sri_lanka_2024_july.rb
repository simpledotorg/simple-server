# frozen_string_literal: true

class SetUpMobitelTestSmsReminderSriLanka2024July < ActiveRecord::Migration[6.1]
  PATIENTS_PER_DAY = 5000
  EXPERIMENT_DATE = "Jul 2024"
  EXPERIMENT_START_TIME = EXPERIMENT_DATE.to_datetime.beginning_of_month
  EXPERIMENT_END_TIME = EXPERIMENT_DATE.to_datetime.end_of_month
  EXPERIMENT_NAME = "Mobitel Test: Current Patient #{EXPERIMENT_DATE}"

  INCLUDED_FACILITY_SLUGS = Facility.where(slug: "dh-gonaduwa").pluck(:slug)
  REGION_FILTERS = {"facilities" => {"include" => INCLUDED_FACILITY_SLUGS}}

  def up
    return unless CountryConfig.current_country?("Sri Lanka") && SimpleServer.env.production?

    # Skipping the setup because there's already a current patient experiment for July
    #
    # ActiveRecord::Base.transaction do
    #   Experimentation::Experiment.current_patients.create!(
    #     name: EXPERIMENT_NAME,
    #     start_time: EXPERIMENT_START_TIME,
    #     end_time: EXPERIMENT_END_TIME,
    #     max_patients_per_day: PATIENTS_PER_DAY,
    #     filters: REGION_FILTERS
    #   ).tap do |experiment|
    #     cascade = experiment.treatment_groups.create!(description: "sms_reminders_cascade - #{EXPERIMENT_NAME}")
    #     cascade.reminder_templates.create!(message: "notifications.sri_lanka.one_day_before_appointment", remind_on_in_days: -1)
    #     cascade.reminder_templates.create!(message: "notifications.sri_lanka.three_days_missed_appointment", remind_on_in_days: 3)
    #   end
    # end
  end

  def down
    return unless CountryConfig.current_country?("Sri Lanka") && SimpleServer.env.production?
    # Experimentation::Experiment.current_patients.find_by_name(EXPERIMENT_NAME)&.cancel
  end
end
