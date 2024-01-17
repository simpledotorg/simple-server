require "rails_helper"

RSpec.describe BulkApiImport::FhirConditionImporter do
  let(:facility) { create(:facility) }
  let(:org_id) { facility.organization_id }
  let(:import_user) { ImportUser.find_or_create(org_id: org_id) }
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
    it "imports a condition" do
      identifier = patient_identifier.identifier
      expect {
        described_class.new(
          resource: build_condition_import_resource.merge(subject: {identifier: identifier}),
          organization_id: org_id
        ).import
      }.to change(MedicalHistory, :count).by(1)
    end

    it "it ensures no conditions are duplicated" do
      identifier = patient_identifier.identifier
      expect {
        2.times do
          described_class.new(
            resource: build_condition_import_resource.merge(subject: {identifier: identifier}),
            organization_id: org_id
          ).import
        end
      }.to change(MedicalHistory, :count).by(1)
    end

    it "accumulates diagnoses" do
      identifier = patient_identifier.identifier
      expect {
        described_class.new(
          resource: build_condition_import_resource.merge(
            subject: {identifier: identifier},
            code: {coding: [{code: "38341003"}]}
          ),
          organization_id: org_id
        ).import
      }.to change { MedicalHistory.order(created_at: :desc).first&.hypertension }.from(nil).to("yes")
    end
  end

  describe "#build_attributes" do
    it "correctly builds valid attributes across different blood pressure resources" do
      10.times.map { build_condition_import_resource }.each do |resource|
        condition_resource = resource.merge(subject: {identifier: patient_identifier.identifier})

        attributes = described_class.new(resource: condition_resource, organization_id: org_id).build_attributes

        expect(Api::V3::MedicalHistoryPayloadValidator.new(attributes)).to be_valid
        expect(attributes[:patient_id]).to eq(patient.id)
      end
    end
  end

  describe "#diagnoses" do
    it "extracts diagnoses for diabetes and hypertension" do
      identifier = patient_identifier.identifier
      [
        {coding: [], expected: {hypertension: "no", diabetes: "no"}},
        {coding: [{code: "38341003"}], expected: {hypertension: "yes", diabetes: "no"}},
        {coding: [{code: "73211009"}], expected: {hypertension: "no", diabetes: "yes"}},
        {coding: [{code: "38341003"}, {code: "73211009"}], expected: {hypertension: "yes", diabetes: "yes"}}
      ].each do |coding:, expected:|
        expect(
          described_class.new(
            resource: {subject: {identifier: identifier}, code: {coding: coding}}, organization_id: org_id
          ).diagnoses
        ).to eq(expected)
      end
    end
  end
end
