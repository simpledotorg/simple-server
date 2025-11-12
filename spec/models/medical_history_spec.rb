require "rails_helper"

describe MedicalHistory, type: :model do
  describe "Associations" do
    it { should belong_to(:patient).optional }
  end

  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
    it { should validate_presence_of(:device_updated_at) }
  end

  describe "Scopes" do
    describe ".for_sync" do
      it "includes discarded medical histories" do
        discarded_medical_history = create(:medical_history, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_medical_history)
      end
    end
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "#indicates_hypertension_risk?" do
    it "is true if there was a prior heart attack" do
      patient = create(:patient)
      create(:medical_history, prior_heart_attack: "yes", patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to eq(true)
    end

    it "is true if there was a prior stroke" do
      patient = create(:patient)
      create(:medical_history, prior_stroke: "yes", patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to eq(true)
    end

    it "does not take prior_heart_attack_boolean or prior_stroke_boolean into account" do
      patient = create(:patient)
      create(:medical_history, prior_heart_attack_boolean: true, prior_stroke_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to eq(false)
    end
  end

  describe "diagnosed_confirmed_at computation on patient" do
    let(:patient) { create(:patient, diagnosed_confirmed_at: nil) }

    it "sets to htn_diagnosed_at when only HTN is present" do
      t = 3.days.ago
      create(:medical_history, patient: patient, htn_diagnosed_at: t, dm_diagnosed_at: nil)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(t.to_i)
    end

    it "sets to dm_diagnosed_at when only DM is present" do
      t = 5.days.ago
      create(:medical_history, patient: patient, htn_diagnosed_at: nil, dm_diagnosed_at: t)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(t.to_i)
    end

    it "sets to the earliest of HTN and DM when both present" do
      htn = 4.days.ago
      dm = 7.days.ago
      create(:medical_history, patient: patient, htn_diagnosed_at: htn, dm_diagnosed_at: dm)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(dm.to_i)
    end

    it "remains nil when both diagnosis timestamps are nil" do
      create(:medical_history, patient: patient, htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(patient.reload.diagnosed_confirmed_at).to be_nil
    end

    it "does not overwrite with a later date if an earlier one is already set" do
      earlier = 10.days.ago
      later = 2.days.ago
      patient.update!(diagnosed_confirmed_at: earlier)
      create(:medical_history, patient: patient, htn_diagnosed_at: later, dm_diagnosed_at: nil)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(earlier.to_i)
    end

    it "does not update to an earlier date once diagnosed_confirmed_at is set" do
      current = 5.days.ago
      earlier = 15.days.ago
      patient.update!(diagnosed_confirmed_at: current)
      create(:medical_history, patient: patient, htn_diagnosed_at: earlier, dm_diagnosed_at: nil)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(current.to_i)
    end
  end

  describe "immutable diagnosis dates" do
    let(:patient) { create(:patient) }
    it "prevents changing htn_diagnosed_at once set" do
      history = create(:medical_history, patient: patient, htn_diagnosed_at: 5.days.ago)
      expect {
        history.update(htn_diagnosed_at: 1.day.ago)
      }.to_not change { history.reload.htn_diagnosed_at }
      expect(history.errors[:htn_diagnosed_at]).to include("Hypertension diagnosis date has already been recorded and cannot be changed.")
    end

    it "prevents changing dm_diagnosed_at once set" do
      history = create(:medical_history, patient: patient, dm_diagnosed_at: 5.days.ago)
      expect {
        history.update(dm_diagnosed_at: 1.day.ago)
      }.to_not change { history.reload.dm_diagnosed_at }
      expect(history.errors[:dm_diagnosed_at]).to include("Diabetes diagnosis date has already been recorded and cannot be changed.")
    end

    it "allows setting the other diagnosis when one is already set" do
      history = create(:medical_history, patient: patient, htn_diagnosed_at: 5.days.ago, dm_diagnosed_at: nil)
      expect(history.update(dm_diagnosed_at: 2.days.ago)).to be true
    end

    it "allows setting either when both are nil" do
      history = create(:medical_history, patient: patient, htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(history.update(htn_diagnosed_at: 3.days.ago)).to be true
    end
  end
end
