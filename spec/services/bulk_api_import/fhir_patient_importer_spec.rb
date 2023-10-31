require "rails_helper"

RSpec.describe BulkApiImport::FhirPatientImporter do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:org_id) { import_user.organization_id }
  let(:facility) { import_user.facility }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end

  describe "#import" do
    it "imports a patient" do
      expect {
        described_class.new(
          resource: build_patient_import_resource
            .merge(managingOrganization: [{value: facility_identifier.identifier}])
            .except(:registrationOrganization),
          organization_id: org_id
        ).import
      }.to change(Patient, :count).by(1)
        .and change(PatientBusinessIdentifier, :count).by(1)
    end

    context "when a patient is imported twice" do
      it "does not duplicate the patient or its nested resources" do
        patient_resource = build_patient_import_resource.merge(address: [{line: ["abc"]}])

        expect {
          described_class.new(
            resource: patient_resource
              .merge(managingOrganization: [{value: facility_identifier.identifier}])
              .except(:registrationOrganization),
            organization_id: org_id
          ).import
        }.to change(Patient, :count).by(1)
          .and change(PatientBusinessIdentifier, :count).by(1)
          .and change(Address, :count).by(1)

        expect {
          described_class.new(
            resource: patient_resource
              .merge(managingOrganization: [{value: facility_identifier.identifier}])
              .except(:registrationOrganization),
            organization_id: org_id
          ).import
        }.to change(Patient, :count).by(0)
          .and change(PatientBusinessIdentifier, :count).by(0)
          .and change(Address, :count).by(0)
      end
    end
  end

  describe "#build_attributes" do
    it "correctly builds valid attributes across different patient resources" do
      10.times.map { build_patient_import_resource }.each do |resource|
        patient_resource = resource
          .merge(managingOrganization: [{value: facility_identifier.identifier}])
          .except(:registrationOrganization)

        attributes = described_class.new(resource: patient_resource, organization_id: org_id)
          .build_attributes
          .merge(request_user_id: import_user)

        expect(Api::V3::PatientPayloadValidator.new(attributes)).to be_valid
      end
    end

    it "correctly extracts gender" do
      [
        {input: "male", expected: "male"},
        {input: "female", expected: "female"},
        {input: "other", expected: "transgender"}
      ].map do |input:, expected:|
        patient_resource = build_patient_import_resource
          .merge(managingOrganization: [{value: facility_identifier.identifier}], gender: input)
          .except(:registrationOrganization)

        expect(described_class.new(resource: patient_resource, organization_id: org_id).build_attributes[:gender])
          .to eq(expected)
      end
    end

    it "correctly extracts name when present" do
      patient_resource = build_patient_import_resource
        .merge(managingOrganization: [{value: facility_identifier.identifier}], name: {text: "naem"})
        .except(:registrationOrganization)

      expect(described_class.new(resource: patient_resource, organization_id: org_id).build_attributes[:full_name])
        .to eq("naem")
    end

    it "generates a name when not present in the resource" do
      patient_resource = build_patient_import_resource
        .merge(managingOrganization: [{value: facility_identifier.identifier}])
        .except(:registrationOrganization, :name)

      expect(described_class.new(resource: patient_resource, organization_id: org_id).build_attributes[:full_name])
        .to match(/Anonymous \w/)
    end
  end

  describe "#status" do
    it "correctly marks the status of an imported patient resource" do
      [
        {input: {deceasedBoolean: true, active: true}, expected_value: "dead"},
        {input: {deceasedBoolean: true, active: false}, expected_value: "dead"},
        {input: {deceasedBoolean: false, active: true}, expected_value: "active"},
        {input: {deceasedBoolean: false, active: false}, expected_value: "inactive"}
      ].each do |input:, expected_value:|
        expect(described_class.new(resource: input, organization_id: org_id).status).to eq(expected_value)
      end
    end
  end

  describe "#phone_numbers" do
    it "correctly populates phone_type and active attributes" do
      [
        {input: {identifier: [value: "foo"], telecom: [{use: "mobile"}]}, expected_phone_type: "mobile", expected_active: true},
        {input: {identifier: [value: "foo"], telecom: [{use: "home"}]}, expected_phone_type: "landline", expected_active: true},
        {input: {identifier: [value: "foo"], telecom: [{use: "work"}]}, expected_phone_type: "landline", expected_active: true},
        {input: {identifier: [value: "foo"], telecom: [{use: "temp"}]}, expected_phone_type: "landline", expected_active: true},
        {input: {identifier: [value: "foo"], telecom: [{use: "old"}]}, expected_phone_type: "mobile", expected_active: false}
      ].each do |input:, expected_phone_type:, expected_active:|
        expect(described_class.new(resource: input, organization_id: org_id).phone_numbers[0])
          .to include(phone_type: expected_phone_type, active: expected_active)
      end
    end
  end

  describe "#address" do
    it "correctly extracts address details" do
      expect(
        described_class.new(
          resource: {
            identifier: [value: "foo"],
            address: [{line: %w[a b], district: "xyz", state: "foo", postalCode: "000"}]
          },
          organization_id: org_id
        ).address
      ).to include(street_address: "a\nb", district: "xyz", state: "foo", pin: "000")
    end
  end

  describe "#business_identifiers" do
    it "correctly extracts business identifiers" do
      expect(
        described_class.new(
          resource: {identifier: [{value: "abc"}]}, organization_id: org_id
        ).business_identifiers.first
      ).to include(identifier: "abc", identifier_type: :external_import_id)
    end
  end
end
