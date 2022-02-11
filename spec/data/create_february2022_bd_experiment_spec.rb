require "rails_helper"
require Rails.root.join("db", "data", "20220211100928_create_february2022_bd_experiment")

RSpec.describe CreateFebruary2022BdExperiment do
  it "creates the current experiment" do
    described_class.new.up

    experiment = Experimentation::CurrentPatientExperiment.first

    expect(experiment).to be_current_patients
    expect(experiment.name).to eq("Current patient experiment February 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Feb 12, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Mar 14, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(5000)

    expect(experiment.treatment_groups.pluck(:description)).to contain_exactly("basic_cascade", "free_cascade")
    expect(experiment.reminder_templates.count).to eq(6)
    expect(experiment.reminder_templates.where(remind_on_in_days: -1).count).to eq(2)
    expect(experiment.reminder_templates.where(remind_on_in_days: 0).count).to eq(2)
    expect(experiment.reminder_templates.where(remind_on_in_days: 3).count).to eq(2)
  end

  it "creates the stale experiment" do
    described_class.new.up

    experiment = Experimentation::StalePatientExperiment.first

    expect(experiment).to be_stale_patients
    expect(experiment.name).to eq("Stale patient experiment February 2022")
    expect(experiment.start_time.to_date).to eq(Date.parse("Feb 12, 2022").to_date)
    expect(experiment.end_time.to_date).to eq(Date.parse("Mar 14, 2022").to_date)
    expect(experiment.max_patients_per_day).to eq(2000)

    expect(experiment.treatment_groups.pluck(:description)).to contain_exactly("single_notification", "cascade")
    expect(experiment.reminder_templates.count).to eq(4)
    expect(experiment.reminder_templates.where(remind_on_in_days: 0).count).to eq(2)
    expect(experiment.reminder_templates.where(remind_on_in_days: 1).count).to eq(1)
    expect(experiment.reminder_templates.where(remind_on_in_days: 4).count).to eq(1)
  end
end

