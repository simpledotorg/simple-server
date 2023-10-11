require "rails_helper"

RSpec.describe BulkApiImport::FhirPatientImporter do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:facility) { import_user.facility }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end

  describe "#import" do
    it "imports a patient" do
      expect {
        described_class.new(
          build_patient_import_resource
            .merge(managingOrganization: [{value: facility_identifier.identifier}])
            .except(:registrationOrganization)
        ).import
      }.to change(Patient, :count).by(1)
        .and change(PatientBusinessIdentifier, :count).by(1)
    end
  end

  describe "#import" do
    it "imports the same patient twice without duplicating embedded resources" do
      patient_resource = build_patient_import_resource.merge(address: [{line: ["abc"]}])
      expect {
        described_class.new(
          patient_resource
            .merge(managingOrganization: [{value: facility_identifier.identifier}])
            .except(:registrationOrganization)
        ).import

        described_class.new(
          patient_resource.merge(deceasedBoolean: true)
            .merge(managingOrganization: [{value: facility_identifier.identifier}])
            .except(:registrationOrganization)
        ).import
      }.to change(Patient, :count).by(1)
        .and change(PatientBusinessIdentifier, :count).by(1)
        .and change(Address, :count).by(1)
    end
  end

  describe "#build_attributes" do
    it "correctly builds valid attributes across different patient resources" do
      10.times.map { build_patient_import_resource }.each do |resource|
        patient_resource = resource
          .merge(managingOrganization: [{value: facility_identifier.identifier}])
          .except(:registrationOrganization)

        attributes = described_class.new(patient_resource).build_attributes
          .merge(request_user_id: import_user)

        expect(Api::V3::PatientPayloadValidator.new(attributes)).to be_valid
      end
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
        expect(described_class.new(input).status).to eq(expected_value)
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
        expect(described_class.new(input).phone_numbers[0])
          .to include(phone_type: expected_phone_type, active: expected_active)
      end
    end
  end

  describe "#address" do
    specify do
      expect(described_class.new({
        identifier: [value: "foo"],
        address: [{line: %w[a b],
                   district: "xyz",
                   state: "foo",
                   postalCode: "000"}]
      }).address).to include(street_address: "a\nb", district: "xyz", state: "foo", pin: "000")
    end
  end

  describe "#business_identifiers" do
    specify do
      expect(described_class.new({identifier: [{value: "abc"}]}).business_identifiers.first)
        .to include(identifier: "abc", identifier_type: :external_import_id)
    end
  end
end
