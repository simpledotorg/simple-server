# frozen_string_literal: true

require "rails_helper"

RSpec.describe MergePatientService, type: :model do
  describe "#merge" do
    let!(:user) { create(:user) }
    let!(:registration_facility) { user.facility }
    let!(:metadata) { {request_facility_id: registration_facility.id, request_user_id: user.id} }

    context "Assigned facility" do
      context "when assigned_facility_id param is available" do
        it "sets to param assigned_facility_id" do
          assigned_facility = create(:facility)
          patient_attributes =
            build_patient_payload(
              build(:patient,
                registration_facility: registration_facility,
                assigned_facility: assigned_facility)
            )

          payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
          merged_patient = described_class.new(payload, request_metadata: metadata).merge

          expect(merged_patient[:assigned_facility_id]).to eq(assigned_facility.id)
        end
      end

      context "when assigned_facility_id param is missing" do
        context "for new patients" do
          it "sets to registration_facility_id from request" do
            patient = build(:patient)
            patient_attributes = build_patient_payload(patient).except(:assigned_facility_id)

            payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
            merged_patient = described_class.new(payload, request_metadata: metadata).merge

            expect(merged_patient[:assigned_facility_id]).to eq(patient_attributes[:registration_facility_id])
          end
        end

        context "for existing patients" do
          it "sets to existing registration_facility_id" do
            patient = create(:patient, registration_facility: registration_facility)
            patient_attributes = build_patient_payload(patient).except(:assigned_facility_id)

            payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
            merged_patient = described_class.new(payload, request_metadata: metadata).merge

            expect(merged_patient[:assigned_facility_id]).to eq(registration_facility.id)
          end
        end
      end
    end

    it "should discard_data when deleted_at exists and the patient is not already deleted" do
      patient = create(:patient)
      now = Time.current
      # set the updated_at so that it is treated as an update
      patient_attributes = build_patient_payload(patient).merge(updated_at: now, deleted_at: now)
      payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)

      expect_any_instance_of(Patient).to receive(:discard_data)
      described_class.new(payload, request_metadata: metadata).merge
    end

    it "touches the patient if patient associations are updated" do
      patient = create(:patient)

      updated_phone_numbers = build(:patient_phone_number, patient: patient)
      updated_business_ids = build(:patient_business_identifier, patient: patient)
      updated_address = build(:address)
      updated_attributes =
        build_patient_payload(patient)
          .merge(
            "phone_numbers" => [build_patient_phone_number_payload(updated_phone_numbers)],
            "address" => updated_address.attributes.with_payload_keys,
            "business_identifiers" => [build_business_identifier_payload(updated_business_ids)]
          )

      payload = Api::V3::PatientTransformer.from_nested_request(updated_attributes)
      described_class.new(payload, request_metadata: metadata).merge

      expect {
        described_class.new(payload, request_metadata: metadata).merge
        patient.reload
      }.to change { patient.updated_at }
    end

    it "sets metadata for a new patient" do
      new_patient_attrs = build_patient_payload.merge(registration_facility_id: registration_facility.id)
      payload = Api::V3::PatientTransformer.from_nested_request(new_patient_attrs)

      merged_patient = described_class.new(payload, request_metadata: metadata).merge

      expect(merged_patient.registration_user).to eq(user)
      expect(merged_patient.registration_facility).to eq(registration_facility)
    end

    it "doesn't update metadata for existing patient" do
      existing_patient = create(:patient)
      existing_patient_attrs = build_patient_payload(existing_patient)
      payload = Api::V3::PatientTransformer.from_nested_request(existing_patient_attrs)

      merged_patient = described_class.new(payload, request_metadata: metadata).merge

      expect(merged_patient.registration_user).to eq(existing_patient.registration_user)
      expect(merged_patient.registration_facility).to eq(existing_patient.registration_facility)
    end
  end
end
