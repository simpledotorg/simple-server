require "rails_helper"
require Rails.root.join("db", "data", "20220510130045_create_may2022_ihci_experiment")

RSpec.describe CreateMay2022IhciExperiment do
  it "creates the current experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("Current Patient May 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("May 13, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Jun 12, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.where("remind_on_in_days < 0").pluck(:message)).to all eq("notifications.set01.basic")
    expect(experiment.reminder_templates.where("remind_on_in_days = 0").pluck(:message)).to all eq("notifications.set02.basic")
    expect(experiment.reminder_templates.where("remind_on_in_days > 0").pluck(:message)).to all start_with("notifications.set03")
  end

  it "creates the stale experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::StalePatientExperiment.first

    expect(experiment).to be_stale_patients
    expect(experiment.name).to eq("Stale Patient May 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("May 13, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Jun 12, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(15000)

    expect(experiment.reminder_templates.pluck(:message)).to all start_with("notifications.set03")
  end
end
