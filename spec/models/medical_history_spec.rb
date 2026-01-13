require "rails_helper"
require_relative "shared_examples/diagnosed_confirmed_at_sync_spec"

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

  describe "#backfill_diagnosed_dates" do
    let(:device_created_at) { 3.days.ago.change(usec: 0) }
    let(:patient) { create(:patient, :without_medical_history, recorded_at: 5.days.ago.change(usec: 0), diagnosed_confirmed_at: nil) }

    it "backfills htn_diagnosed_at from device_created_at when hypertension is yes and dates are nil" do
      mh = create(:medical_history, patient: patient, hypertension: "yes", htn_diagnosed_at: nil, dm_diagnosed_at: nil, device_created_at: device_created_at)
      expect(mh.htn_diagnosed_at.to_i).to eq(device_created_at.to_i)
    end

    it "backfills dm_diagnosed_at from device_created_at when diabetes is yes and dates are nil" do
      mh = create(:medical_history, patient: patient, diabetes: "yes", htn_diagnosed_at: nil, dm_diagnosed_at: nil, device_created_at: device_created_at)
      expect(mh.dm_diagnosed_at.to_i).to eq(device_created_at.to_i)
    end

    it "backfills htn_diagnosed_at from device_created_at when hypertension is no and dates are nil" do
      mh = create(:medical_history, patient: patient, hypertension: "no", htn_diagnosed_at: nil, dm_diagnosed_at: nil, device_created_at: device_created_at)
      expect(mh.htn_diagnosed_at.to_i).to eq(device_created_at.to_i)
    end

    it "backfills dm_diagnosed_at from device_created_at when diabetes is no and dates are nil" do
      mh = create(:medical_history, patient: patient, diabetes: "no", htn_diagnosed_at: nil, dm_diagnosed_at: nil, device_created_at: device_created_at)
      expect(mh.dm_diagnosed_at.to_i).to eq(device_created_at.to_i)
    end

    it "does not backfill for suspected statuses" do
      mh = create(:medical_history, patient: patient, hypertension: "suspected", htn_diagnosed_at: nil, device_created_at: device_created_at)
      expect(mh.htn_diagnosed_at).to be_nil
    end
  end

  describe "#update_patient_diagnosed_confirmed_at" do
    it_behaves_like "a record that syncs diagnosed_confirmed_at"

    let(:patient) { create(:patient, :without_medical_history, recorded_at: 5.days.ago.change(usec: 0), diagnosed_confirmed_at: nil) }

    it "sets patient.diagnosed_confirmed_at when patient is not yet associated (race condition)" do
      htn_time = 3.days.ago.change(usec: 0)
      create(:medical_history, patient_id: patient.id, patient: nil, hypertension: "yes", htn_diagnosed_at: htn_time)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(htn_time.to_i)
    end

    it "sets patient.diagnosed_confirmed_at to dm_diagnosed_at when only DM date present (other suspected)" do
      dm_time = 5.days.ago.change(usec: 0)
      create(:medical_history, patient: patient, diabetes: "no", hypertension: "suspected", htn_diagnosed_at: nil, dm_diagnosed_at: dm_time)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(dm_time.to_i)
    end

    it "sets patient.diagnosed_confirmed_at to earliest date when both dates present" do
      htn = 4.days.ago.change(usec: 0)
      dm = 7.days.ago.change(usec: 0)
      create(:medical_history, patient: patient, hypertension: "yes", diabetes: "no", htn_diagnosed_at: htn, dm_diagnosed_at: dm)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(dm.to_i)
    end

    it "does not set diagnosed_confirmed_at when both conditions are suspected" do
      create(:medical_history, patient: patient, hypertension: "suspected", diabetes: "suspected",
             htn_diagnosed_at: 4.days.ago.change(usec: 0), dm_diagnosed_at: 3.days.ago.change(usec: 0))
      expect(patient.reload.diagnosed_confirmed_at).to be_nil
    end
  end

  describe "immutable diagnosis dates and transitions" do
    let(:patient) { create(:patient) }

    it "silently preserves htn_diagnosed_at once set" do
      original_date = 5.days.ago.change(usec: 0)
      history = create(:medical_history, patient: patient, htn_diagnosed_at: original_date, hypertension: "yes")
      result = history.update(htn_diagnosed_at: 1.day.ago.change(usec: 0))
      expect(result).to be true
      expect(history.errors).to be_blank
      expect(history.reload.htn_diagnosed_at.to_i).to eq(original_date.to_i)
    end

    it "silently preserves dm_diagnosed_at once set" do
      original_date = 5.days.ago.change(usec: 0)
      history = create(:medical_history, patient: patient, dm_diagnosed_at: original_date, diabetes: "yes")
      result = history.update(dm_diagnosed_at: 1.day.ago.change(usec: 0))
      expect(result).to be true
      expect(history.errors).to be_blank
      expect(history.reload.dm_diagnosed_at.to_i).to eq(original_date.to_i)
    end

    it "allows setting the other diagnosis when one is already set (confirmed + suspected)" do
      history = create(:medical_history,
        patient: patient,
        hypertension: "yes",
        diabetes: "suspected",
        htn_diagnosed_at: 5.days.ago.change(usec: 0),
        dm_diagnosed_at: nil)
      expect(history.update(dm_diagnosed_at: 2.days.ago.change(usec: 0))).to be true
    end

    it "allows setting either when both are nil" do
      history = create(:medical_history, patient: patient, hypertension: "suspected", diabetes: "suspected", htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(history.update(htn_diagnosed_at: 3.days.ago.change(usec: 0))).to be true
    end

    it "does not allow flipping confirmed yes/no when dates are already present (preserves old dates on save)" do
      old_htn = 10.days.ago.change(usec: 0)
      old_dm = 9.days.ago.change(usec: 0)
      mh = create(:medical_history, patient: patient,
                  hypertension: "yes", diabetes: "no",
                  htn_diagnosed_at: old_htn, dm_diagnosed_at: old_dm)

      mh.assign_attributes(hypertension: "no", diabetes: "yes", htn_diagnosed_at: 1.day.ago.change(usec: 0), dm_diagnosed_at: 1.day.ago.change(usec: 0))
      expect(mh.valid?).to be_truthy
      mh.save!
      expect(mh.reload.hypertension).to eq("no")
      expect(mh.reload.diabetes).to eq("yes")
      expect(mh.reload.htn_diagnosed_at.to_i).to eq(old_htn.to_i)
      expect(mh.reload.dm_diagnosed_at.to_i).to eq(old_dm.to_i)
    end
  end
end
