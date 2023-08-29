require "rails_helper"

RSpec.describe BulkApiImport::Validator do
  let(:facility) { create(:facility) }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:organization) { facility.facility_group.organization }

  describe "#validate" do
    context "valid resources and facility IDs" do
      it "does not return any errors" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: facility_identifier.identifier})]
          ).validate
        ).to be_nil
      end
    end

    context "valid resources and invalid facility ID" do
      it "returns an error for unmapped facility IDs" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: "unmapped_identifier"})]
          ).validate
        ).to have_key(:invalid_facility_error)
      end
    end

    context "valid resources and valid facility ID, but incorrect organization" do
      it "returns an error for unmapped facility IDs" do
        expect(
          described_class.new(
            organization: "some_other_organization",
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: facility_identifier.identifier})]
          ).validate
        ).to have_key(:invalid_facility_error)
      end
    end

    context "invalid resource" do
      it "returns a schema error" do
        expect(
          described_class.new(organization: organization.id, resources: [{invalid: :resource}]).validate
        ).to have_key(:schema_errors)
      end
    end
  end

  describe "#validate_schema" do
    context "valid resources" do
      it "returns no error" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource]
          ).validate_schema
        ).to be_nil
      end
    end

    context "invalid resource" do
      it "returns a schema error" do
        expect(
          described_class.new(organization: organization.id, resources: [{invalid: :resource}]).validate_schema
        ).to have_key(:schema_errors)
      end
    end
  end

  describe "#validate_facilities" do
    context "valid facility IDs" do
      it "does not return any errors" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: facility_identifier.identifier})]
          ).validate_facilities
        ).to be_nil
      end
    end

    context "invalid facility ID" do
      it "returns an error for unmapped facility IDs" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: "unmapped_identifier"})]
          ).validate_facilities
        ).to have_key(:invalid_facility_error)
      end
    end

    context "valid resources and valid facility ID, but incorrect organization" do
      it "returns an error for unmapped facility IDs" do
        expect(
          described_class.new(
            organization: "some_other_organization",
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: facility_identifier.identifier})]
          ).validate_facilities
        ).to have_key(:invalid_facility_error)
      end
    end
  end

  describe "resource facility extractors" do
    it "extracts facilities from patient resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_patient_import_resource
              .merge(managingOrganization: [{value: "abc"}])
              .except(:registrationOrganization),
            build_patient_import_resource
              .merge(managingOrganization: [{value: "abc"}], registrationOrganization: [{value: "xyz"}])
          ]
        ).patient_resource_facilities
      ).to match_array(%w[abc xyz])
    end

    it "extracts facilities from appointment resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_appointment_import_resource
              .merge(appointmentOrganization: {identifier: "abc"})
              .except(:appointmentCreationOrganization),
            build_appointment_import_resource
              .merge(appointmentOrganization: {identifier: "abc"}, appointmentCreationOrganization: {identifier: "xyz"})
          ]
        ).appointment_resource_facilities
      ).to match_array(%w[abc xyz])
    end

    it "extracts facilities from observation resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_observation_import_resource(:blood_sugar).merge(performer: [{identifier: "abc"}]),
            build_observation_import_resource(:blood_pressure).merge(performer: [{identifier: "xyz"}])
          ]
        ).observation_resource_facilities
      ).to match_array(%w[abc xyz])
    end

    it "extracts facilities from medication request resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_medication_request_import_resource.merge(performer: {identifier: "abc"}),
            build_medication_request_import_resource.merge(performer: {identifier: "xyz"})
          ]
        ).medication_request_resource_facilities
      ).to match_array(%w[abc xyz])
    end
  end
end
