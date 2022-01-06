# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::PatientTransformer do
  describe "from_nested_request" do
    context "request payload has reminder consent" do
      let(:request_patient) { build_patient_payload.merge("reminder_consent" => "denied") }

      it "adds a default `granted` reminder_consent" do
        transformed_nested_patient = Api::V3::PatientTransformer.from_nested_request(request_patient)
        expect(transformed_nested_patient[:reminder_consent]).to eq(request_patient["reminder_consent"])
      end
    end

    context "request payload does not have reminder consent" do
      let(:request_patient) { build_patient_payload.except("reminder_consent") }

      it "adds a default `granted` reminder_consent" do
        transformed_nested_patient = Api::V3::PatientTransformer.from_nested_request(request_patient)
        expect(transformed_nested_patient[:reminder_consent]).to eq("granted")
      end
    end

    context "Existing patient, request payload does not have reminder consent" do
      let!(:patient) { create(:patient) }
      let(:request_patient) { build_patient_payload(patient).except("reminder_consent") }
      it "adds the patients existing reminder_consent value" do
        transformed_nested_patient = Api::V3::PatientTransformer.from_nested_request(request_patient)
        expect(transformed_nested_patient[:reminder_consent]).to eq(patient["reminder_consent"])
      end
    end
  end

  describe "to_nested_response" do
    let!(:patient) { create(:patient) }
    it "includes reminder_consent in the response" do
      transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient)
      expect(transformed_nested_patient["reminder_consent"]).to eq(patient.reminder_consent)
    end

    it "includes registration_facility in the response" do
      transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient)
      expect(transformed_nested_patient["registration_facility_id"]).to eq(patient.registration_facility.id)
    end
  end
end
