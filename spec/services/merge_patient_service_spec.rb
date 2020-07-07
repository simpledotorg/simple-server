# we pick registrayion facility from params
# if regist facility is not present/nil, we pick it up from the headers
# we pick assigned f from params
# if not present assign it to reg facility
#

require "rails_helper"

RSpec.describe MergePatientService, type: :model do
  describe "#merge" do
    context "Assigned facility" do
      let!(:user) { create(:user) }
      let!(:registration_facility) { user.facility }
      let!(:metadata) { {registration_facility_id: registration_facility.id, registration_user_id: user.id} }

      it "keeps assigned_facility_id if it is already present" do
        assigned_facility = build(:facility)
        patient_attributes =
          build_patient_payload(
            build(:patient,
              registration_facility: registration_facility,
              assigned_facility: assigned_facility))
            .merge(metadata: metadata)

        payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
        merged_patient = described_class.new(payload).merge

        expect(merged_patient[:assigned_facility_id]).to eq(assigned_facility.id)
      end

      it "sets to registration_facility_id if assigned facility missing" do
        patient_attributes =
          build_patient_payload(
            build(:patient,
              registration_facility: registration_facility,
              assigned_facility: nil))
            .merge(metadata: metadata)

        payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
        merged_patient = described_class.new(payload).merge

        expect(merged_patient[:assigned_facility_id]).to eq(registration_facility.id)
      end

      it "should set registration_user_id and reg_facility_id and get rid of metadata" do
        patient_attributes =
          build_patient_payload(
            build(:patient,
                  registration_facility: registration_facility,
                  assigned_facility: nil))
            .merge(metadata: metadata)

        payload = Api::V3::PatientTransformer.from_nested_request(patient_attributes)
        described_class.new(payload).merge

        expect(Patient.find(patient_attributes[:id]).registration_facility.id).to eq(registration_facility.id)
        expect(Patient.find(patient_attributes[:id]).registration_user.id).to eq(user.id)
      end
    end
  end
end
