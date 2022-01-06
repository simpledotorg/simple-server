# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::TeleconsultationMedicalOfficerTransformer do
  describe ".to_response" do
    let!(:medical_officer) { create(:teleconsultation_medical_officer) }

    it "includes user attributes" do
      response = described_class.to_response(medical_officer)
      expect(response).to eq("id" => medical_officer.id,
        "full_name" => medical_officer.full_name,
        "teleconsultation_phone_number" => medical_officer.full_teleconsultation_phone_number)
    end
  end
end
