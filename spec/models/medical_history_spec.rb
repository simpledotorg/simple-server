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

  describe "creation (app sends both dates when available)" do
    let(:patient) { create(:patient, :without_medical_history, diagnosed_confirmed_at: nil) }
    let(:htn_time) { 3.days.ago.change(usec: 0) }
    let(:dm_time) { 2.days.ago.change(usec: 0) }

    it "creates when hypertension: yes, diabetes: no -> persists both dates sent by app" do
      mh = create(:medical_history, patient: patient, hypertension: "yes", diabetes: "no",
                  htn_diagnosed_at: htn_time, dm_diagnosed_at: dm_time)
      expect(mh.htn_diagnosed_at.to_i).to eq(htn_time.to_i)
      expect(mh.dm_diagnosed_at.to_i).to eq(dm_time.to_i)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(htn_time.to_i)
    end

    it "creates when hypertension: no, diabetes: yes -> persists both dates sent by app" do
      mh = create(:medical_history, patient: patient, hypertension: "no", diabetes: "yes",
                  htn_diagnosed_at: htn_time, dm_diagnosed_at: dm_time)
      expect(mh.htn_diagnosed_at.to_i).to eq(htn_time.to_i)
      expect(mh.dm_diagnosed_at.to_i).to eq(dm_time.to_i)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(htn_time.to_i)
    end

    it "creates when hypertension: no, diabetes: no -> persists both dates sent by app" do
      mh = create(:medical_history, patient: patient, hypertension: "no", diabetes: "no",
                  htn_diagnosed_at: htn_time, dm_diagnosed_at: dm_time)
      expect(mh.htn_diagnosed_at.to_i).to eq(htn_time.to_i)
      expect(mh.dm_diagnosed_at.to_i).to eq(dm_time.to_i)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(htn_time.to_i)
    end

    it "creates when hypertension: yes, diabetes: yes -> persists both dates sent by app" do
      mh = create(:medical_history, patient: patient, hypertension: "yes", diabetes: "yes",
                  htn_diagnosed_at: htn_time, dm_diagnosed_at: dm_time)
      expect(mh.htn_diagnosed_at.to_i).to eq(htn_time.to_i)
      expect(mh.dm_diagnosed_at.to_i).to eq(dm_time.to_i)
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(htn_time.to_i)
    end
  end

  describe "#backfill_diagnosed_dates" do
    let(:patient) { create(:patient, :without_medical_history, diagnosed_confirmed_at: nil) }

    it "backfills htn_diagnosed_at from patient.recorded_at when hypertension is yes and both timestamps nil" do
      patient.update!(recorded_at: 5.days.ago.change(usec: 0))
      mh = create(:medical_history, patient: patient, hypertension: "yes", htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(mh.htn_diagnosed_at.to_i).to eq(patient.recorded_at.to_i)
    end

    it "backfills dm_diagnosed_at from patient.recorded_at when diabetes is yes and both timestamps nil" do
      patient.update!(recorded_at: 5.days.ago.change(usec: 0))
      mh = create(:medical_history, patient: patient, diabetes: "yes", htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(mh.dm_diagnosed_at.to_i).to eq(patient.recorded_at.to_i)
    end

    it "does not backfill if patient.recorded_at is nil" do
      patient.update!(recorded_at: nil)
      mh = create(:medical_history, patient: patient, hypertension: "yes", diabetes: "no", htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(mh.htn_diagnosed_at).to be_nil
      expect(mh.dm_diagnosed_at).to be_nil
    end

    it "does not persist dates when hypertension is suspected (even if app sends them)" do
      mh = create(:medical_history, patient: patient, hypertension: "suspected", diabetes: "no",
                  htn_diagnosed_at: 3.days.ago.change(usec: 0), dm_diagnosed_at: 2.days.ago.change(usec: 0))
      expect(mh.htn_diagnosed_at).to be_nil
      expect(mh.dm_diagnosed_at).to be_nil
      expect(patient.reload.diagnosed_confirmed_at).to be_nil
    end

    it "does not persist dates when diabetes is suspected (even if app sends them)" do
      mh = create(:medical_history, patient: patient, hypertension: "no", diabetes: "suspected",
                  htn_diagnosed_at: 3.days.ago.change(usec: 0), dm_diagnosed_at: 2.days.ago.change(usec: 0))
      expect(mh.htn_diagnosed_at).to be_nil
      expect(mh.dm_diagnosed_at).to be_nil
      expect(patient.reload.diagnosed_confirmed_at).to be_nil
    end
  end

  describe "updates (app sends both dates when available)" do
    let(:patient) { create(:patient) }
    let(:old_htn) { 10.days.ago.change(usec: 0) }
    let(:old_dm) { 9.days.ago.change(usec: 0) }
    let(:new_htn) { 3.days.ago.change(usec: 0) }
    let(:new_dm) { 2.days.ago.change(usec: 0) }

    it "does not overwrite existing dates when both already present (flipping yes/no combos)" do
      mh = create(:medical_history, patient: patient,
                   hypertension: "yes", diabetes: "no",
                   htn_diagnosed_at: old_htn, dm_diagnosed_at: old_dm)
      mh.assign_attributes(hypertension: "no", diabetes: "yes",
        htn_diagnosed_at: new_htn, dm_diagnosed_at: new_dm)
      mh.valid?
      expect(mh.htn_diagnosed_at.to_i).to eq(old_htn.to_i)
      expect(mh.dm_diagnosed_at.to_i).to eq(old_dm.to_i)
    end

    it "when suspected -> confirmed, accepts new dates if server had none" do
      mh = create(:medical_history, patient: patient,
                   hypertension: "suspected", diabetes: "no",
                   htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      mh.assign_attributes(hypertension: "yes", diabetes: "no",
        htn_diagnosed_at: new_htn, dm_diagnosed_at: new_dm)
      mh.valid?
      expect(mh.htn_diagnosed_at.to_i).to eq(new_htn.to_i)
      expect(mh.dm_diagnosed_at.to_i).to eq(new_dm.to_i)
    end
  end

  describe "#update_patient_diagnosed_confirmed_at" do
    let(:patient) { create(:patient, :without_medical_history, diagnosed_confirmed_at: nil) }

    it "sets patient.diagnosed_confirmed_at to earliest of provided dates when no suspected" do
      create(:medical_history, patient: patient, hypertension: "yes", diabetes: "yes",
             htn_diagnosed_at: 4.days.ago.change(usec: 0), dm_diagnosed_at: 3.days.ago.change(usec: 0))
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(4.days.ago.change(usec: 0).to_i)
    end

    it "does not set diagnosed_confirmed_at when any suspected present" do
      create(:medical_history, patient: patient, hypertension: "suspected", diabetes: "yes",
             htn_diagnosed_at: 4.days.ago.change(usec: 0), dm_diagnosed_at: 3.days.ago.change(usec: 0))
      expect(patient.reload.diagnosed_confirmed_at).to be_nil
    end

    it "does not overwrite an already-set diagnosed_confirmed_at" do
      earlier = 10.days.ago.change(usec: 0)
      patient.update_columns(diagnosed_confirmed_at: earlier)
      create(:medical_history, patient: patient, hypertension: "yes", diabetes: "no",
             dm_diagnosed_at: 2.days.ago.change(usec: 0), htn_diagnosed_at: 1.day.ago.change(usec: 0))
      expect(patient.reload.diagnosed_confirmed_at.to_i).to eq(earlier.to_i)
    end
  end

  describe "immutable diagnosis dates" do
    let(:patient) { create(:patient) }

    it "silently preserves htn_diagnosed_at once set" do
      original_date = 5.days.ago.change(usec: 0)
      history = create(:medical_history, patient: patient, htn_diagnosed_at: original_date)
      result = history.update(htn_diagnosed_at: 1.day.ago.change(usec: 0))

      expect(result).to be true
      expect(history.errors).to be_blank
      expect(history.reload.htn_diagnosed_at.to_i).to eq(original_date.to_i)
    end

    it "silently preserves dm_diagnosed_at once set" do
      original_date = 5.days.ago.change(usec: 0)
      history = create(:medical_history, patient: patient, dm_diagnosed_at: original_date)
      result = history.update(dm_diagnosed_at: 1.day.ago.change(usec: 0))

      expect(result).to be true
      expect(history.errors).to be_blank
      expect(history.reload.dm_diagnosed_at.to_i).to eq(original_date.to_i)
    end

    it "allows setting the other diagnosis when one is already set" do
      history = create(:medical_history, patient: patient, htn_diagnosed_at: 5.days.ago.change(usec: 0), dm_diagnosed_at: nil)
      expect(history.update(dm_diagnosed_at: 2.days.ago.change(usec: 0))).to be true
    end

    it "allows setting either when both are nil" do
      history = create(:medical_history, patient: patient, htn_diagnosed_at: nil, dm_diagnosed_at: nil)
      expect(history.update(htn_diagnosed_at: 3.days.ago.change(usec: 0))).to be true
    end

    it "does not raise an error if htn_diagnosed_at is updated with the same value" do
      date = 5.days.ago.change(usec: 0)
      history = create(:medical_history, patient: patient, htn_diagnosed_at: date)

      result = history.update(htn_diagnosed_at: date)
      expect(result).to be true
      expect(history.reload.htn_diagnosed_at.to_i).to eq(date.to_i)
    end

    it "does not raise an error if dm_diagnosed_at is updated with the same value" do
      date = 5.days.ago.change(usec: 0)
      history = create(:medical_history, patient: patient, dm_diagnosed_at: date)

      result = history.update(dm_diagnosed_at: date)
      expect(result).to be true
      expect(history.reload.dm_diagnosed_at.to_i).to eq(date.to_i)
    end
  end
end
