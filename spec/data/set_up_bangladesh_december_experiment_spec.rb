require "rails_helper"
require Rails.root.join("db", "data", "20231109143922_set_up_bangladesh_december_experiment.rb")

describe SetUpBangladeshDecemberExperiment do
  context "when experiment is set up" do
    it "enrolls eligible patients in given facilities as expected" do
      allow(CountryConfig).to receive(:current_country?).with("Bangladesh").and_return true
      stub_const("SIMPLE_SERVER_ENV", "production")

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
end
