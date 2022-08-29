require "rails_helper"
require Rails.root.join("db", "data", "20220829130543_create_sept2022_ihci_experiments")

RSpec.describe CreateSept2022IhciExperiments do
  it "creates the current experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("Current Patient Sept 2022 Basic Variations")
    expect(experiment.start_time.to_date).to eq(Date.parse("Aug 30, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Sep 29, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.count).to eq(2)
    expect(experiment.reminder_templates.pluck(:message)).to all start_with("notifications.set03")
    expect(experiment.reminder_templates.pluck(:remind_on_in_days)).to contain_exactly(3, 7)
  end

  it "creates the stale experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::StalePatientExperiment.first

    expect(experiment).to be_stale_patients
    expect(experiment.name).to eq("Stale Patient Sept 2022 Basic Variations")
    expect(experiment.start_time.to_date).to eq(Date.parse("Aug 30, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Sep 29, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.count).to eq(2)
    expect(experiment.reminder_templates.where("remind_on_in_days = 0").pluck(:message)).to all start_with("notifications.set02")
    expect(experiment.reminder_templates.where("remind_on_in_days > 0").pluck(:message)).to all start_with("notifications.set03")
    expect(experiment.reminder_templates.pluck(:remind_on_in_days)).to contain_exactly(0, 7)
  end
end
