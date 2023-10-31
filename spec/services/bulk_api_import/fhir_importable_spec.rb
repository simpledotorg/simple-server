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

    it "provides a different translation for a different organization having the same facility identifier" do
      identifier_from_first_org = facility_identifiers.identifier
      other_org = create(:organization, id: SecureRandom.uuid, name: "Another Org")
      other_facility_group = create(:facility_group, organization: other_org)
      other_facility = create(:facility, facility_group: other_facility_group)
      create(:facility_business_identifier, identifier: identifier_from_first_org,
             facility: other_facility, identifier_type: :external_org_facility_id)

      expect(Object.new.extend(described_class)
          .translate_facility_id(facility_identifiers.identifier, org_id: other_org.id))
        .to eq(other_facility.id)
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
