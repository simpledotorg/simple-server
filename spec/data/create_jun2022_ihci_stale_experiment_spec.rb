require "rails_helper"
require Rails.root.join("db", "data", "20220510130045_create_jun2022_stale_ihci_experiment")

RSpec.describe CreateMay2022IhciExperiment do
  it "creates the stale experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::StalePatientExperiment.first

    expect(experiment).to be_stale_patients
    expect(experiment.name).to eq("Stale Patient May 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Jun 1, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Jun 30, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(15000)

    expect(experiment.reminder_templates.pluck(:message)).to all start_with("notifications.set03")
  end
end
