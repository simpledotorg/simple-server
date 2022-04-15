require "rails_helper"
require Rails.root.join("db", "data", "20220412130957_create_apr2022_ihci_experiment")

RSpec.describe CreateApr2022IhciExperiment do
  it "creates the current experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("Current Patient April 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Apr 12, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("May 12, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(20000)

    group_names = %w[control basic_cascade gratitude_cascade free_cascade alarm_cascade emotional_relatives_cascade emotional_guilt_cascade professional_request_cascade]

    expect(experiment.treatment_groups.pluck(:description)).to match_array(group_names)
    expect(experiment.reminder_templates.count).to eq(21)
    expect(experiment.reminder_templates.where(remind_on_in_days: -1).count).to eq(7)
    expect(experiment.reminder_templates.where(remind_on_in_days: 0).count).to eq(7)
    expect(experiment.reminder_templates.where(remind_on_in_days: 3).count).to eq(7)
  end

  it "creates the stale experiment" do
    allow(CountryConfig).to receive(:current_country?).with("India").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")

    described_class.new.up

    experiment = Experimentation::StalePatientExperiment.first

    expect(experiment).to be_stale_patients
    expect(experiment.name).to eq("Stale Patient April 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Apr 12, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("May 12, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(15000)

    group_names = %w[control basic_single_notification gratitude_single_notification free_single_notification alarm_single_notification emotional_relatives_single_notification emotional_guilt_single_notification professional_request_single_notification]

    expect(experiment.treatment_groups.pluck(:description)).to match_array(group_names)
    expect(experiment.reminder_templates.count).to eq(7)
    expect(experiment.reminder_templates.where(remind_on_in_days: 0).count).to eq(7)
  end
end
