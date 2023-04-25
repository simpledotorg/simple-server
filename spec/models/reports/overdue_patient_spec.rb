require "rails_helper"

RSpec.describe Reports::OverduePatient, {type: :model, reporting_spec: true} do

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "Model" do
    it "should not include dead patients" do
      create(:patient)
      dead_patient = create(:patient, status: "dead")
      Reports::PatientState.refresh
      described_class.refresh

      with_reporting_time_zone do
        expect(described_class.count).not_to eq 0
        expect(described_class.where(patient_id: dead_patient.id)).to be_empty
      end
    end
  end

  context "indicators" do
    describe "next_called_at" do
      it "should only select the call that took place during the month" do end
      it "should not select the call that took place after the month" do end
      it "should not select the call that took place before the month" do end
    end
    describe "previous_called_at" do
      it "should only select the latest call in the previous month" do end
      it "should only select the call that was made after the latest appointment" do end
    end
    describe "previous_appointment_id" do
      it "should only select the latest appointment in the previous month" do end
      it "should pick cancelled appointments also" do end
    end
    describe "is_overdue" do
      it "should be no when the previous appointments scheduled date is during the month" do end
      it "should be no when the previous appointments scheduled date is in the previous month and the visit date is during the month" do end
      it "should be yes when the previous appointments scheduled date and visited date is in the previous month and the visit took place after the scheduled date" do end
    end
    describe "has_called" do
      it "should be yes if the patient has atleast one phone linked" do end
      it "should be no if the patient has no active phone linked" do end
    end
    describe "has_visited_following_call" do
      it "should be no when there was no visit" do end
      it "should be no when a call was not made" do end
      it "should be no when a call was made but the patient visited after 15 days" do end
      it "should be yes when a call was made and the patient visited within 15 days" do end
    end
    describe "ltfu" do end
    describe "under_care" do end
    describe "has_phone" do end
    describe "removed_from_overdue_list" do
      it "should be yes when the call result corresponding to the prevous appointment is removed_from_overdue_list" do end
    end
  end
end
