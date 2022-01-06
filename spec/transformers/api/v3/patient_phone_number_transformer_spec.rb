# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::PatientPhoneNumberTransformer do
  describe "to_response" do
    let(:phone_number) { build(:patient_phone_number) }

    it "removes patient_id and dnd_status" do
      transformed_phone_number = Api::V3::PatientPhoneNumberTransformer.to_response(phone_number)

      expect(transformed_phone_number).not_to include("patient_id", "dnd_status")
    end

    it "replaces phone_types other than mobile and landline with mobile" do
      phone_number = build(:patient_phone_number, phone_type: :invalid)
      transformed_phone_number = Api::V3::PatientPhoneNumberTransformer.to_response(phone_number)
      expect(transformed_phone_number["phone_type"]).to eq("mobile")
    end
  end

  describe "from_request" do
    let(:phone_number_payload) { build_patient_phone_number_payload }

    it "removes dnd_status and phone_type from the request" do
      transformed_payload = Api::V3::PatientPhoneNumberTransformer.from_request(phone_number_payload)

      expect(transformed_payload).not_to include("dnd_status", "phone_type")
    end
  end
end
