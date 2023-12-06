require "rails_helper"

RSpec.describe BulkApiImport::FhirAppointmentImporter do
  let(:facility) { create(:facility) }
  let(:org_id) { facility.organization_id }
  let(:import_user) { ImportUser.find_or_create(org_id: org_id) }
  let(:facility_identifiers) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end

  describe "#import" do
    it "imports an appointment" do
      expect {
        described_class.new(
          resource: build_appointment_import_resource
            .merge(appointmentOrganization: {identifier: facility_identifiers.identifier})
            .except(:appointmentCreationOrganization),
          organization_id: org_id
        ).import
      }.to change(Appointment, :count).by(1)
    end
  end

  describe "#build_attributes" do
    it "correctly builds valid attributes across different appointment resources" do
      10.times.map { build_appointment_import_resource }.each do |resource|
        appointment_resource = resource
          .merge(appointmentOrganization: {identifier: facility_identifiers.identifier})
          .except(:appointmentCreationOrganization)

        attributes = described_class.new(resource: appointment_resource, organization_id: org_id).build_attributes

        expect(Api::V3::AppointmentPayloadValidator.new(attributes)).to be_valid
      end
    end
  end

  describe "#scheduled_date" do
    specify {
      expect(described_class.new(resource: {start: "2023-08-07T07:50:38Z"}, organization_id: org_id).scheduled_date)
        .to eq("2023-08-07")
    }
    specify { expect(described_class.new(resource: {}, organization_id: org_id).scheduled_date).to be_nil }
  end

  describe "#facility_id" do
    it "extracts facility ID" do
      expect(described_class.new(
        resource: {appointmentOrganization: {identifier: facility_identifiers.identifier}},
        organization_id: org_id
      ).facility_id).to eq(facility.id)
    end
  end
end
