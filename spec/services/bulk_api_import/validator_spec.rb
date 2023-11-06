require "rails_helper"

RSpec.describe BulkApiImport::Validator do
  let(:facility) { create(:facility) }
  let(:patient) { create(:patient) }
  let(:facility_identifier) do
    create(:facility_business_identifier, facility: facility, identifier_type: :external_org_facility_id)
  end
  let(:patient_identifier) do
    create(:patient_business_identifier, patient: patient, identifier_type: :external_import_id)
  end
  let(:organization) { facility.facility_group.organization }

  describe "#validate" do
    context "valid resources and facility IDs" do
      it "does not return any errors" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                         .merge(performer: {identifier: facility_identifier.identifier},
                           subject: {identifier: patient_identifier.identifier})]
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
                          .merge(performer: {identifier: "unmapped_identifier"},
                            subject: {identifier: patient_identifier.identifier})]
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

    context "valid resources and facility ID, but invalid patient ID" do
      it "returns an error for unmapped patient IDs" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                          .merge(performer: {identifier: facility_identifier.identifier},
                            subject: {identifier: "unmapped_patient"})]
          ).validate
        ).to have_key(:invalid_patient_error)
      end
    end

    context "valid resources and valid facility ID, but invalid HTN observation codes" do
      it "returns an error about invalid observation codes" do
        bp_with_two_diastolic_codes = build_observation_import_resource(:blood_pressure).merge(
          performer: [{identifier: facility_identifier.identifier}],
          subject: {identifier: patient_identifier.identifier},
          component: [
            {code: {coding: [system: "http://loinc.org", code: "8462-4"]},
             valueQuantity: blood_pressure_value_quantity(:systolic)},
            {code: {coding: [system: "http://loinc.org", code: "8462-4"]},
             valueQuantity: blood_pressure_value_quantity(:systolic)}
          ]
        )

        expect(
          described_class.new(
            organization: organization.id,
            resources: [bp_with_two_diastolic_codes]
          ).validate
        ).to have_key(:invalid_observation_codes_error)
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

  describe "#validate_patients" do
    context "valid patient IDs" do
      it "does not return any errors" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                          .merge(subject: {identifier: patient_identifier.identifier})]
          ).validate_patients
        ).to be_nil
      end
    end

    context "invalid patient ID" do
      it "returns an error for unmapped patient IDs" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource
                          .merge(subject: {identifier: "unmapped_identifier"})]
          ).validate_patients
        ).to have_key(:invalid_patient_error)
      end
    end

    context "valid resources and valid patient ID, but incorrect organization" do
      it "returns an error for unmapped facility IDs" do
        expect(
          described_class.new(
            organization: "some_other_organization",
            resources: [build_medication_request_import_resource
                          .merge(subject: {identifier: patient_identifier.identifier})]
          ).validate_patients
        ).to have_key(:invalid_patient_error)
      end
    end
  end

  describe "#validate_observation_codes" do
    context "valid non-observation resources" do
      it "does not return any error" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_medication_request_import_resource]
          ).validate_observation_codes
        ).to be_nil
      end
    end

    context "valid observation resources" do
      it "does not return any error" do
        expect(
          described_class.new(
            organization: organization.id,
            resources: [build_observation_import_resource(:blood_sugar)]
          ).validate_observation_codes
        ).to be_nil
      end
    end

    context "invalid observation resources" do
      it "returns an error highlighting any unknown codes" do
        bp_with_unknown_code = build_observation_import_resource(:blood_pressure).merge(
          performer: [{identifier: facility_identifier.identifier}],
          component: [
            {code: {coding: [system: "http://loinc.org", code: "foo"]},
             valueQuantity: blood_pressure_value_quantity(:systolic)},
            {code: {coding: [system: "http://loinc.org", code: "8462-4"]},
             valueQuantity: blood_pressure_value_quantity(:diastolic)}
          ]
        )

        expect(
          described_class.new(
            organization: organization.id,
            resources: [bp_with_unknown_code]
          ).validate_observation_codes[:invalid_observation_codes_error]
        ).to include(invalid_observations: {bp_with_unknown_code[:identifier][0][:value] => %w[foo 8462-4]})
      end

      it "returns an error when an HTN code is duplicated" do
        bp_with_duplicate_code = build_observation_import_resource(:blood_pressure).merge(
          performer: [{identifier: facility_identifier.identifier}],
          component: [
            {code: {coding: [system: "http://loinc.org", code: "8480-6"]},
             valueQuantity: blood_pressure_value_quantity(:systolic)},
            {code: {coding: [system: "http://loinc.org", code: "8480-6"]},
             valueQuantity: blood_pressure_value_quantity(:diastolic)}
          ]
        )

        expect(
          described_class.new(
            organization: organization.id,
            resources: [bp_with_duplicate_code]
          ).validate_observation_codes[:invalid_observation_codes_error]
        ).to include(invalid_observations: {bp_with_duplicate_code[:identifier][0][:value] => %w[8480-6 8480-6]})
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

  describe "resource patient extractors" do
    it "extracts patients from appointment resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_appointment_import_resource
              .merge(participant: [{actor: {identifier: "abc"}}]),
            build_appointment_import_resource
              .merge(participant: [{actor: {identifier: "xyz"}}])
          ]
        ).appointment_resource_patients
      ).to match_array(%w[abc xyz])
    end

    it "extracts patients from observation resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_observation_import_resource(:blood_sugar).merge(subject: {identifier: "abc"}),
            build_observation_import_resource(:blood_pressure).merge(subject: {identifier: "xyz"})
          ]
        ).observation_resource_patients
      ).to match_array(%w[abc xyz])
    end

    it "extracts patients from medication request resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_medication_request_import_resource.merge(subject: {identifier: "abc"}),
            build_medication_request_import_resource.merge(subject: {identifier: "xyz"})
          ]
        ).medication_request_resource_patients
      ).to match_array(%w[abc xyz])
    end

    it "extracts patients from condition resources" do
      expect(
        described_class.new(
          organization: "",
          resources: [
            build_condition_import_resource
              .merge(subject: {identifier: "abc"}),
            build_condition_import_resource
              .merge(subject: {identifier: "xyz"})
          ]
        ).condition_resource_patients
      ).to match_array(%w[abc xyz])
    end
  end
end
