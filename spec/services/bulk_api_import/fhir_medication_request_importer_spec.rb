require "rails_helper"

RSpec.describe BulkApiImport::FhirMedicationRequestImporter do
  let(:facility) { create(:facility) }
  let(:org_id) { facility.organization_id }
  let(:import_user) { ImportUser.find_or_create(org_id: org_id) }
  let(:org_id) { facility.organization_id }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:identifier) { SecureRandom.uuid }
  let(:patient) do
    build_stubbed(:patient, id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE + org_id, identifier))
  end
  let(:patient_identifier) do
    build_stubbed(:patient_business_identifier, patient: patient,
                  identifier: identifier,
                  identifier_type: :external_import_id)
  end

  describe "#import" do
    it "imports a medication request" do
      expect {
        described_class.new(
          resource: build_medication_request_import_resource
            .merge(performer: {identifier: facility_identifier.identifier},
              subject: {identifier: patient_identifier.identifier}),
          organization_id: org_id
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

        attributes = described_class.new(resource: med_request_resource, organization_id: org_id).build_attributes

        expect(Api::V3::PrescriptionDrugPayloadValidator.new(attributes)).to be_valid
        expect(attributes[:patient_id]).to eq(patient.id)
      end
    end
  end

  describe "#contained_medication" do
    it "fetches the contained medication" do
      expect(described_class.new(resource: {contained: [{code: {}}]}, organization_id: "").contained_medication)
        .to eq({code: {}})
    end
  end

  describe "#frequency" do
    it "extracts the frequency type" do
      [
        {input_code: "QD", expected_value: :OD},
        {input_code: "BID", expected_value: :BD},
        {input_code: "TID", expected_value: :TDS},
        {input_code: "QID", expected_value: :QDS}
      ].each do |input_code:, expected_value:|
        expect(described_class.new(
          resource: {
            dosageInstruction: [{timing: {code: input_code}}]
          },
          organization_id: ""
        ).frequency).to eq(expected_value)
      end
    end
  end

  describe "#dosage" do
    it "extracts dosage value" do
      [
        {dose_and_rate_value: nil,
         text_value: nil,
         expected_dosage: nil},
        {dose_and_rate_value: [],
         text_value: nil,
         expected_dosage: nil},
        {dose_and_rate_value: nil,
         text_value: "10mg OD",
         expected_dosage: "10mg OD"},
        {dose_and_rate_value: [],
         text_value: "10mg OD",
         expected_dosage: "10mg OD"},
        {dose_and_rate_value: [{doseQuantity: {value: 10, unit: "mg"}}],
         text_value: nil,
         expected_dosage: "10 mg"},
        {dose_and_rate_value: [{doseQuantity: {value: 10, unit: "mL"}}],
         text_value: "10mL OD",
         expected_dosage: "10 mL"}
      ].each do |dose_and_rate_value:, text_value:, expected_dosage:|
        expect(described_class.new(
          resource: {
            dosageInstruction: [{doseAndRate: dose_and_rate_value,
                                 text: text_value}]
          },
          organization_id: org_id
        ).dosage).to eq(expected_dosage)
      end
    end
  end

  describe "#drug_deleted?" do
    it "infers drug deletion status" do
      [
        {status: "active", deletion_status: false},
        {status: "inactive", deletion_status: true},
        {status: "inactive", deletion_status: true}
      ].each do |status:, deletion_status:|
        expect(described_class.new(resource: {contained: [{status: status}]}, organization_id: "").drug_deleted?)
          .to eq(deletion_status)
      end
    end
  end
end
