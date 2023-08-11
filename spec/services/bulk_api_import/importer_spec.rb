require "rails_helper"

RSpec.describe BulkApiImport::Importer do
  before { FactoryBot.create(:facility) } # needed for our bot import user

  describe "#import" do
    let(:organization) { FactoryBot.create(:organization) }
    let(:facility) { Facility.first }
    let(:facility_identifier) do
      create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
    end
    let(:patient) { create(:patient) }
    let(:patient_identifier) do
      create(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
    end

    it "imports patient resources" do
      resources = 2.times.map { build_patient_import_resource }

      expect { described_class.new(resource_list: resources).import }
        .to change(Patient, :count).by(2)
    end

    it "imports appointment resources" do
      resources = 2.times.map do
        build_appointment_import_resource.merge(
          appointmentOrganization: {identifier: facility_identifier.identifier},
          appointmentCreationOrganization: nil
        )
      end

      expect { described_class.new(resource_list: resources).import }
        .to change(Appointment, :count).by(2)
    end

    it "imports observation resources" do
      resources = [
        build_observation_import_resource(:blood_pressure)
          .merge(performer: [{identifier: facility_identifier.identifier}],
            subject: {identifier: patient_identifier.identifier}),
        build_observation_import_resource(:blood_sugar)
          .merge(performer: [{identifier: facility_identifier.identifier}],
            subject: {identifier: patient_identifier.identifier})
      ]

      expect { described_class.new(resource_list: resources).import }
        .to change(BloodPressure, :count).by(1)
        .and change(BloodSugar, :count).by(1)
        .and change(Encounter, :count).by(2)
        .and change(Observation, :count).by(2)
    end
  end

  describe "#resource_importer" do
    it "fetches the correct importer" do
      importer = described_class.new(resource_list: [])

      [
        {input: {resourceType: "Patient"}, expected_importer: BulkApiImport::FhirPatientImporter},
        {input: {resourceType: "Appointment"}, expected_importer: BulkApiImport::FhirAppointmentImporter},
        {input: {resourceType: "Observation"}, expected_importer: BulkApiImport::FhirObservationImporter}
      ].each do |input:, expected_importer:|
        expect(importer.resource_importer(input)).to be_an_instance_of(expected_importer)
      end
    end
  end
end
