# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db", "data", "20230620114230_set_up_six_month_ihci_sms_reminders")

RSpec.describe SetUpSixMonthIhciSmsReminders do
  it "sets up cascading current and stale experiments for July through December 2023" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    expect(Experimentation::CurrentPatientExperiment.count).to eq(6)
    expect(Experimentation::StalePatientExperiment.count).to eq(6)

    current_reminder_templates = Experimentation::CurrentPatientExperiment.first.reminder_templates
    expect(current_reminder_templates.count).to eq(2)
    expect(current_reminder_templates.find_by(remind_on_in_days: 3).message).to eq("notifications.set03.official_short")
    expect(current_reminder_templates.find_by(remind_on_in_days: 7).message).to eq("notifications.set03.official_short")

    stale_reminder_templates = Experimentation::StalePatientExperiment.first.reminder_templates
    expect(stale_reminder_templates.count).to eq(2)
    expect(stale_reminder_templates.find_by(remind_on_in_days: 0).message).to eq("notifications.set02.official_short")
    expect(stale_reminder_templates.find_by(remind_on_in_days: 7).message).to eq("notifications.set03.official_short")
  end
end
