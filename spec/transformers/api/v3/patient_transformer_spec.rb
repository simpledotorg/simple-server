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

    context "when the patient has no address (optional address)" do
      it "does not raise and serializes the patient with a nil address" do
        patient.update_columns(address_id: nil)
        expect {
          transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient)
          expect(transformed_nested_patient["address"]).to be_nil
        }.not_to raise_error
      end
    end

    context "when the patient's address row has been hard-deleted (orphaned address_id)" do
      it "does not raise and serializes the patient with a nil address" do
        ActiveRecord::Base.connection.disable_referential_integrity do
          Address.where(id: patient.address_id).delete_all
        end
        expect(patient.reload.address).to be_nil
        expect {
          transformed_nested_patient = Api::V3::PatientTransformer.to_nested_response(patient)
          expect(transformed_nested_patient["address"]).to be_nil
        }.not_to raise_error
      end
    end
  end
end
