require "rails_helper"
require Rails.root.join("db", "data", "20220608124339_create_jun2022_ihci_current_experiment")

RSpec.describe CreateJun2022IhciCurrentExperiment do
  it "creates the current experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("Current Patient June 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Jun 13, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Jun 30, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    expect(experiment.reminder_templates.where("remind_on_in_days < 0").pluck(:message)).to all eq("notifications.set01.basic")
    expect(experiment.reminder_templates.where("remind_on_in_days = 0").pluck(:message)).to all eq("notifications.set02.basic")
    expect(experiment.reminder_templates.where("remind_on_in_days > 0").pluck(:message)).to all start_with("notifications.set03")
  end
end
