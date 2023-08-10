require "rails_helper"

RSpec.describe BulkApiImport::Importer do
  before { FactoryBot.create(:facility) } # needed for our bot import user

  describe "#import" do
    let(:organization) { FactoryBot.create(:organization) }
    let(:facility) { Facility.first }
    let(:facility_identifiers) do
      create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
    end

    it "imports patient resources" do
      resources = 2.times.map { build_patient_import_resource }

      expect { described_class.new(resource_list: resources).import }
        .to change(Patient, :count).by(2)
    end

    it "does not actually import non-patient resources" do
      resources = 2.times.map {
        build_appointment_import_resource
          .merge(appointmentOrganization: {identifier: facility_identifiers.identifier},
            appointmentCreationOrganization: nil)
      }

      expect { described_class.new(resource_list: resources).import }
        .not_to change(Appointment, :count)
    end
  end

  describe "#resource_importer" do
    it "fetches the correct importer" do
      importer = described_class.new(resource_list: [])

      [
        {input: {resourceType: "Patient"}, expected_importer: BulkApiImport::FhirPatientImporter}
        # {input: {resourceType: "Appointment"}, expected_importer: BulkApiImport::FhirAppointmentImporter},
        # {input: {resourceType: "Observation"}, expected_importer: BulkApiImport::FhirObservationImporter}
      ].each do |input:, expected_importer:|
        expect(importer.resource_importer(input)).to be_an_instance_of(expected_importer)
      end
    end
  end
end
