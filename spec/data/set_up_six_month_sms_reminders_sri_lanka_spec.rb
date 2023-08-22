# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db", "data", "20230808085832_set_up_six_month_sms_reminders_sri_lanka.rb")

describe SetUpSixMonthSmsRemindersSriLanka do
  it "sets up cascading current experiments for September 2023 through February 2024" do
    allow(CountryConfig).to receive(:current_country?).with("Sri Lanka").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    expect(Experimentation::CurrentPatientExperiment.count).to eq(6)
    current_reminder_templates = Experimentation::CurrentPatientExperiment.first.reminder_templates
    expect(current_reminder_templates.count).to eq(2)
    expect(current_reminder_templates.find_by(remind_on_in_days: -1).message).to eq("notifications.sri_lanka.one_day_before_appointment")
    expect(current_reminder_templates.find_by(remind_on_in_days: 3).message).to eq("notifications.sri_lanka.three_days_missed_appointment")
  end
end
