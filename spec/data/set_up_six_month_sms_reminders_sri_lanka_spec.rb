# frozen_string_literal: true

require 'rails_helper'
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

  it "sets the correct message data in each membership" do
    allow(CountryConfig).to receive(:current_country?).with("Sri Lanka").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    d = Date.current
    experiment = Experimentation::CurrentPatientExperiment.first
    treatment_group = experiment.treatment_groups.first
    membership = create(:treatment_group_membership, treatment_group_id: treatment_group.id)
    allow(experiment).to receive(:memberships_to_notify).with(d).and_return([membership])
    experiment.schedule_notifications(d)

    puts membership
  end
end
