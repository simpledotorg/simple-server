require "rails_helper"

RSpec.describe BulkApiImport::Importer do
  before { FactoryBot.create(:facility) } # needed for our bot import user

  describe "#import" do
    let(:facility) { Facility.first }
    let(:organization_id) { facility.organization_id }
    let(:facility_identifier) do
      create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
    end
    let(:patient) { build_stubbed(:patient) }
    let(:patient_identifier) do
      build_stubbed(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
    end

    it "imports patient resources" do
      resources = 2.times.map do
        build_patient_import_resource
          .merge(managingOrganization: [{value: facility_identifier.identifier}])
          .except(:registrationOrganization)
      end

      expect { described_class.new(resource_list: resources, organization_id: organization_id).import }
        .to change(Patient, :count).by(2)
    end

    it "imports appointment resources" do
      resources = 2.times.map do
        build_appointment_import_resource.merge(
          appointmentOrganization: {identifier: facility_identifier.identifier},
          appointmentCreationOrganization: nil
        )
      end

      expect { described_class.new(resource_list: resources, organization_id: organization_id).import }
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

      expect { described_class.new(resource_list: resources, organization_id: organization_id).import }
        .to change(BloodPressure, :count).by(1)
        .and change(BloodSugar, :count).by(1)
        .and change(Encounter, :count).by(2)
        .and change(Observation, :count).by(2)
    end

    it "imports medication request resources" do
      resources = 2.times.map do
        build_medication_request_import_resource.merge(
          performer: {identifier: facility_identifier.identifier},
          subject: {identifier: patient_identifier.identifier}
        )
      end

      expect { described_class.new(resource_list: resources, organization_id: organization_id).import }
        .to change(PrescriptionDrug, :count).by(2)
    end

    it "imports condition resources" do
      resources = 2.times.map do
        build_condition_import_resource.merge(
          subject: {identifier: patient_identifier.identifier}
        )
      end

      expect { described_class.new(resource_list: resources, organization_id: organization_id).import }
        .to change(MedicalHistory, :count).by(2)
    end
  end

  describe "#resource_importer" do
    it "fetches the correct importer" do
      importer = described_class.new(resource_list: [], organization_id: "org_id")

      [
        {input: {resourceType: "Patient"}, expected_importer: BulkApiImport::FhirPatientImporter},
        {input: {resourceType: "Appointment"}, expected_importer: BulkApiImport::FhirAppointmentImporter},
        {input: {resourceType: "Observation"}, expected_importer: BulkApiImport::FhirObservationImporter},
        {input: {resourceType: "MedicationRequest"}, expected_importer: BulkApiImport::FhirMedicationRequestImporter},
        {input: {resourceType: "Condition"}, expected_importer: BulkApiImport::FhirConditionImporter}
      ].each do |input:, expected_importer:|
        expect(importer.resource_importer(input, "org_id"))
          .to be_an_instance_of(expected_importer)
      end
    end
  end
end
