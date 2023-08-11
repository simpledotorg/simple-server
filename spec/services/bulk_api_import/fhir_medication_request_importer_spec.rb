require "rails_helper"

RSpec.describe BulkApiImport::FhirMedicationRequestImporter do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:facility) { import_user.facility }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:patient) { create(:patient) }
  let(:patient_identifier) do
    create(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
  end

  describe "#import" do
    it "imports a medication request" do
      expect {
        described_class.new(
          build_medication_request_import_resource
            .merge(performer: {identifier: facility_identifier.identifier},
              subject: {identifier: patient_identifier.identifier})
        ).import
      }.to change(PrescriptionDrug, :count).by(1)
    end
  end

  describe "#build_attributes" do
    it "correctly builds valid attributes across different blood pressure resources" do
      10.times.map { build_medication_request_import_resource }.each do |resource|
        med_request_resource = resource
          .merge(performer: {identifier: facility_identifier.identifier},
            subject: {identifier: patient_identifier.identifier})

        attributes = described_class.new(med_request_resource).build_attributes

        expect(Api::V3::PrescriptionDrugPayloadValidator.new(attributes)).to be_valid
      end
    end
  end
end
