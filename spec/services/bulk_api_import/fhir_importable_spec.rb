require "rails_helper"

RSpec.describe BulkApiImport::FhirImportable do
  before { create(:facility) }
  let(:import_user) { ImportUser.find_or_create }
  let(:facility) { import_user.facility }
  let(:org_id) { facility.organization_id }
  let(:facility_identifiers) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end

  describe "#import_user" do
    specify { expect(Object.new.extend(described_class).import_user).to eq(import_user) }
  end

  describe "#translate_facility_id" do
    it "translates the facility ID correctly" do
      expect(Object.new.extend(described_class).translate_facility_id(facility_identifiers.identifier, org_id: org_id))
        .to eq(facility.id)
    end

    it "correctly handles translation of the same business identifier across multiple orgs" do
      clashing_identifier = facility_identifiers.identifier

      org1_id = org_id
      org1_facility = facility

      org2 = create(:organization, id: SecureRandom.uuid, name: "Another Org")
      org2_facility = create(:facility, facility_group: create(:facility_group, organization: org2))
      create(:facility_business_identifier, identifier: clashing_identifier,
             facility: org2_facility, identifier_type: :external_org_facility_id)

      expect(Object.new.extend(described_class).translate_facility_id(clashing_identifier, org_id: org1_id))
        .to eq(org1_facility.id)

      expect(Object.new.extend(described_class)
          .translate_facility_id(clashing_identifier, org_id: org2.id))
        .to eq(org2_facility.id)
    end
  end

  describe "#translate_patient_id" do
    let(:patient_identifier) { SecureRandom.uuid }
    let(:patient) do
      build_stubbed(:patient, id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE + org_id, patient_identifier))
    end
    let(:patient_business_identifier) do
      build_stubbed(:patient_business_identifier, patient: patient,
                    identifier: patient_identifier,
                    identifier_type: :external_import_id)
    end

    it "translates the patient ID correctly" do
      expect(Object.new.extend(described_class).translate_id(patient_business_identifier.identifier, org_id: org_id))
        .to eq(patient.id)
    end

    it "correctly handles translation of the same business identifier across multiple orgs" do
      clashing_identifier = patient_business_identifier.identifier

      org1_id = org_id
      org1_patient = patient

      org2 = create(:organization, id: SecureRandom.uuid, name: "Another Org")
      org2_facility = create(:facility, facility_group: create(:facility_group, organization: org2))
      org2_patient = create(:patient,
        id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE + org2.id, clashing_identifier),
        assigned_facility: org2_facility)
      create(:patient_business_identifier, identifier: clashing_identifier,
             patient: org2_patient, identifier_type: :external_import_id)

      expect(Object.new.extend(described_class).translate_id(clashing_identifier, org_id: org1_id))
        .to eq(org1_patient.id)

      expect(Object.new.extend(described_class).translate_id(clashing_identifier, org_id: org2.id))
        .to eq(org2_patient.id)
    end
  end

  describe "#timestamps" do
    it "extracts timestamp from any FHIR-like resource" do
      fake_importer = Class.new do
        include BulkApiImport::FhirImportable
        def initialize(resource)
          @resource = resource
        end
      end

      t1 = Time.current
      t2 = t1.days_ago(2)
      expect(fake_importer.new({meta: {lastUpdated: t1, createdAt: t2}}).timestamps)
        .to eq({created_at: t2, updated_at: t1})
    end
  end
end
