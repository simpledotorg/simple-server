# frozen_string_literal: true

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
      create(:medical_history, prior_heart_attack_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to eq(true)
    end

    it "is true if there was a prior stroke" do
      patient = create(:patient)
      create(:medical_history, prior_stroke_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to eq(true)
    end

    it "is falsey if there is diabetes history" do
      patient = create(:patient)
      create(:medical_history, diabetes_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to be_falsey
    end

    it "is falsey if there was chronic kidney disease" do
      patient = create(:patient)
      create(:medical_history, chronic_kidney_disease_boolean: true, patient: patient)

      expect(patient.medical_history.indicates_hypertension_risk?).to be_falsey
    end
  end
end
