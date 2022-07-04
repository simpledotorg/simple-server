require "rails_helper"
require Rails.root.join("db", "data", "20220704101607_create_jul2022_ihci_current_aa_experiment")

RSpec.describe CreateJul2022IhciCurrentAaExperiment do
  it "creates the current experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("A/A Current Patient July 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Jul 5, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Jul 10, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.pluck(:message)).to all start_with("notifications.set03_basic_repeated")
  end
end
