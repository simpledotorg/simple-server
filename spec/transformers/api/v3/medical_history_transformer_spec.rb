# frozen_string_literal: true

require "rails_helper"

describe Api::V3::MedicalHistoryTransformer do
  describe "to_response" do
    let(:medical_history) { FactoryBot.build(:medical_history) }
    let(:transformed_medical_history) { described_class.to_response(medical_history) }

    it "removes boolean fields from medical history hashes" do
      MedicalHistory::MEDICAL_HISTORY_QUESTIONS.each do |question|
        expect(transformed_medical_history["#{question}_boolean"]).not_to be_present
      end
    end

    it "removes user_id from medical history response hashes" do
      expect(transformed_medical_history).not_to include("user_id")
    end
  end

  describe "from_request" do
    let(:transformed_params) { described_class.from_request(medical_history_params) }
    context "when hypertension is provided" do
      let(:medical_history_params) do
        {
          id: SecureRandom.uuid,
          patient_id: SecureRandom.uuid,
          hypertension: "no",
          diagnosed_with_hypertension: "unknown"
        }
      end

      it "passes along the received hypertension values" do
        expect(transformed_params[:hypertension]).to eq("no")
        expect(transformed_params[:diagnosed_with_hypertension]).to eq("unknown")
      end
    end

    context "when hypertension is not provided" do
      let(:medical_history_params) do
        {
          id: SecureRandom.uuid,
          patient_id: SecureRandom.uuid,
          diagnosed_with_hypertension: "unknown"
        }
      end

      it "sets hypertension fields to yes" do
        expect(transformed_params[:hypertension]).to eq("yes")
        expect(transformed_params[:diagnosed_with_hypertension]).to eq("yes")
      end
    end
  end
end
