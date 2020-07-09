require "rails_helper"

RSpec.describe MergePatientService, type: :model do
  describe "#merge" do
    let!(:user) { create(:user) }
    let!(:registration_facility) { user.facility }
    let!(:metadata) { {request_facility_id: registration_facility.id, request_user_id: user.id} }

    context "Assigned facility" do
      it "keeps assigned_facility_id if it is already present" do
        assigned_facility = build(:facility)
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

      it "sets to registration_facility_id if assigned facility missing" do
        patient_attributes =
          build_patient_payload(
            build(:patient,
              registration_facility: registration_facility,
              assigned_facility: nil)
          )

        payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
        merged_patient = described_class.new(payload, request_metadata: metadata).merge

        expect(merged_patient[:assigned_facility_id]).to eq(registration_facility.id)
      end
    end

    it "should discard_data when deleted_at exists and is not already deleted" do
      patient = create(:patient)
      now = Time.current
      patient_attributes = build_patient_payload(patient).merge(updated_at: now, deleted_at: now)
      payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)

      expect_any_instance_of(Patient).to receive(:discard_data)
      described_class.new(payload, request_metadata: metadata).merge
    end

    it "should not update phone numbers, address or business identifiers for discarded patients"

    it "sets metadata for a new patient" do
      new_patient_attrs = build_patient_payload
      payload = Api::V3::PatientTransformer.from_nested_request(new_patient_attrs)

      merged_patient = described_class.new(payload, request_metadata: metadata).merge

      expect(merged_patient.registration_user).to eq(user)
      expect(merged_patient.registration_facility).to eq(registration_facility)
    end

    it "doesn't change metadata for existing patient" do
      existing_patient = create(:patient)
      existing_patient_attrs = build_patient_payload(existing_patient)
      payload = Api::V3::PatientTransformer.from_nested_request(existing_patient_attrs)

      merged_patient = described_class.new(payload, request_metadata: metadata).merge

      expect(merged_patient.registration_user).to eq(existing_patient.registration_user)
      expect(merged_patient.registration_facility).to eq(existing_patient.registration_facility)
    end
  end
end
