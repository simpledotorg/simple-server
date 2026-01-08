require "rails_helper"

RSpec.shared_examples "a record that syncs diagnosed_confirmed_at" do
  let(:patient) { create(:patient, :without_medical_history, diagnosed_confirmed_at: nil) }

  context "when syncing diagnosed_confirmed_at" do
    it "sets patient.diagnosed_confirmed_at to the earliest available diagnosis date when blank" do
      htn_date = 5.days.ago.change(usec: 0)
      dm_date = 3.days.ago.change(usec: 0)

      if described_class == MedicalHistory
        create(
          :medical_history,
          patient: patient,
          hypertension: "yes",
          diabetes: "yes",
          htn_diagnosed_at: htn_date,
          dm_diagnosed_at: dm_date
        )
      elsif described_class == Patient
        create(
          :medical_history,
          patient: patient,
          hypertension: "yes",
          diabetes: "yes",
          htn_diagnosed_at: htn_date,
          dm_diagnosed_at: dm_date
        )
        patient.save!
      end

      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(htn_date.to_i)
    end

    it "does not update diagnosed_confirmed_at if it is already present" do
      existing_date = 2.days.ago.change(usec: 0)
      earlier_date = 5.days.ago.change(usec: 0)

      patient.update!(diagnosed_confirmed_at: existing_date)

      if described_class == MedicalHistory
        create(
          :medical_history,
          patient: patient,
          hypertension: "yes",
          htn_diagnosed_at: earlier_date
        )
      elsif described_class == Patient
        create(
          :medical_history,
          patient: patient,
          hypertension: "yes",
          htn_diagnosed_at: earlier_date
        )
        patient.save!
      end

      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(existing_date.to_i)
    end
  end
end
