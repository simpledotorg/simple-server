require "rails_helper"
require Rails.root.join("db", "data", "20220722132318_create_jul2022_ihci_basic_variation_experiments")

RSpec.describe CreateJul2022IhciBasicVariationExperiments do
  it "creates the current experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("Current Patient July 2022 Basic Variations")
    expect(experiment.start_time.to_date).to eq(Date.parse("Jul 23, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Aug 22, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.count).to eq(8*2)
    expect(experiment.reminder_templates.where("remind_on_in_days = 0").pluck(:message)).to all start_with("notifications.set02")
    expect(experiment.reminder_templates.where("remind_on_in_days > 0").pluck(:message)).to all start_with("notifications.set03")
  end

  it "creates the stale experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::StalePatientExperiment.first

    expect(experiment).to be_stale_patients
    expect(experiment.name).to eq("Stale Patient July 2022 Basic Variations")
    expect(experiment.start_time.to_date).to eq(Date.parse("Jul 23, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Aug 22, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.count).to eq(8*2)
    expect(experiment.reminder_templates.where("remind_on_in_days = 0").pluck(:message)).to all start_with("notifications.set02")
    expect(experiment.reminder_templates.where("remind_on_in_days > 0").pluck(:message)).to all start_with("notifications.set03")
  end
end
