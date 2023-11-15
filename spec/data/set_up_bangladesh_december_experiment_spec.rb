require "rails_helper"
require Rails.root.join("db", "data", "20231109143922_set_up_bangladesh_december_experiment.rb")

describe SetUpBangladeshDecemberExperiment do
  before do
    allow(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return true
    stub_const("SIMPLE_SERVER_ENV", "production")
  end

  context "when the data migration is run" do
    it "creates a current and a stale experiment with treatment groups and reminder templates" do
      described_class.new.up

      expect(Experimentation::CurrentPatientExperiment.count).to eq(1)
      expect(Experimentation::StalePatientExperiment.count).to eq(1)

      current_experiment = Experimentation::CurrentPatientExperiment.first
      expect(current_experiment.treatment_groups.count).to eq(5)
      expect(current_experiment.reminder_templates.count).to eq(12)

      stale_experiment = Experimentation::StalePatientExperiment.first
      expect(stale_experiment.treatment_groups.count).to eq(5)
      expect(stale_experiment.reminder_templates.count).to eq(12)
    end

    it "enrolls eligible patients in facilities passed during the experiment" do
      earliest_remind_on = -1.days
      enrollment_date = Date.new(2023, 12, 2)
      appointment_date = enrollment_date - earliest_remind_on

      facility1 = create(:facility, slug: "uhc-agailjhara")
      patient1 = create(:patient, assigned_facility: facility1)
      create(:appointment, patient: patient1, scheduled_date: appointment_date)

      facility2 = create(:facility, slug: "another-facility")
      patient2 = create(:patient, assigned_facility: facility2)
      create(:appointment, patient: patient2, scheduled_date: appointment_date)

      described_class.new.up

      Timecop.freeze(enrollment_date)

      Experimentation::CurrentPatientExperiment.conduct_daily(enrollment_date)
      current_experiment = Experimentation::CurrentPatientExperiment.first
      expect(current_experiment.treatment_group_memberships.count).to eq(1)
      expect(current_experiment.treatment_group_memberships.first&.patient).to eq(patient1)

      Timecop.return
    end
  end

  context "when the migration is rolled back" do
    it "cancels the experiments and their reminder templates and treatment_groups without errors" do
      described_class.new.up
      described_class.new.down

      expect(Experimentation::CurrentPatientExperiment.count).to eq(0)
      expect(Experimentation::StalePatientExperiment.count).to eq(0)
      expect(Experimentation::ReminderTemplate.count).to eq(0)
      expect(Experimentation::TreatmentGroup.count).to eq(0)
    end
  end
end
