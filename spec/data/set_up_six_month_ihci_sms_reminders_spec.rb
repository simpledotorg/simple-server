# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db", "data", "20230620114230_set_up_six_month_ihci_sms_reminders")

RSpec.describe SetUpSixMonthIhciSmsReminders do
  it "sets up cascading current and stale experiments for July through December" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    expect(Experimentation::CurrentPatientExperiment.count).to eq(6)
    expect(Experimentation::StalePatientExperiment.count).to eq(6)

    current_cascade = Experimentation::CurrentPatientExperiment.first.reminder_templates
    expect(current_cascade.count).to eq(2)
    expect(current_cascade.find_by(remind_on_in_days: 3).message).to eq("notifications.set03.official_short")
    expect(current_cascade.find_by(remind_on_in_days: 7).message).to eq("notifications.set03.official_short")

    stale_cascade = Experimentation::StalePatientExperiment.first.reminder_templates
    expect(stale_cascade.count).to eq(2)
    expect(stale_cascade.find_by(remind_on_in_days: 0).message).to eq("notifications.set02.official_short")
    expect(stale_cascade.find_by(remind_on_in_days: 7).message).to eq("notifications.set03.official_short")
  end
end
