require "rails_helper"

RSpec.describe BulkApiImport::FhirAppointmentImporter do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:facility) { import_user.facility }
  let(:facility_identifiers) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end

  describe "#import" do
    it "imports an appointment" do
      expect {
        described_class.new(build_appointment_import_resource
            .merge(appointmentOrganization: {identifier: facility_identifiers.identifier})
            .except(:appointmentCreationOrganization)).import
      }.to change(Appointment, :count).by(1)
    end
  end

  describe "#build_attributes" do
    it "correctly builds valid attributes across different appointment resources" do
      10.times.map { build_appointment_import_resource }.each do |resource|
        appointment_resource = resource
          .merge(appointmentOrganization: {identifier: facility_identifiers.identifier})
          .except(:appointmentCreationOrganization)

        attributes = described_class.new(appointment_resource).build_attributes

        expect(Api::V3::AppointmentPayloadValidator.new(attributes)).to be_valid
      end
    end
  end

  describe "#scheduled_date" do
    specify { expect(described_class.new({start: "2023-08-07T07:50:38Z"}).scheduled_date).to eq("2023-08-07") }
    specify { expect(described_class.new({}).scheduled_date).to be_nil }
  end

  describe "#facility_id" do
    it "extracts facility ID" do
      expect(described_class.new(
        {appointmentOrganization: {identifier: facility_identifiers.identifier}}
      ).facility_id).to eq(facility.id)
    end
  end
end
