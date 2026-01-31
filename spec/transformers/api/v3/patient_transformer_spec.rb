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

    context "when patient has no address" do
      let!(:patient_without_address) { create(:patient, address: nil) }

      it "returns nil for address instead of raising an error" do
        transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient_without_address)
        expect(transformed_nested_patient["address"]).to be_nil
      end
    end

    context "when patient has no phone numbers" do
      let!(:patient_without_phone_numbers) { create(:patient, :without_phone_number) }

      it "returns empty array for phone_numbers" do
        transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient_without_phone_numbers)
        expect(transformed_nested_patient["phone_numbers"]).to eq([])
      end
    end

    context "when patient has no business identifiers" do
      let!(:patient_without_business_identifiers) { create(:patient, business_identifiers: []) }

      it "returns empty array for business_identifiers" do
        transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient_without_business_identifiers)
        expect(transformed_nested_patient["business_identifiers"]).to eq([])
      end
    end

    context "when patient has no address, phone_numbers, or business_identifiers" do
      let!(:patient_without_associations) { create(:patient, address: nil, phone_numbers: [], business_identifiers: []) }

      it "returns nil for address and empty arrays for phone_numbers and business_identifiers" do
        transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient_without_associations)
        expect(transformed_nested_patient["address"]).to be_nil
        expect(transformed_nested_patient["phone_numbers"]).to eq([])
        expect(transformed_nested_patient["business_identifiers"]).to eq([])
      end
    end
  end
end
