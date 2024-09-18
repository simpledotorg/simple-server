require "fhir_models"

module OneOff
  module Opensrp
    class BloodSugarExporter
      attr_reader :blood_sugar, :patient

      def initialize(blood_sugar_or_patient, opensrp_mapping)
        if blood_sugar_or_patient.is_a?(Patient)
          @patient = blood_sugar_or_patient
          @blood_sugar = nil
        else
          @blood_sugar = blood_sugar_or_patient
          @patient = @blood_sugar.patient
        end
        @opensrp_ids = opensrp_mapping[@patient.assigned_facility_id]
      end

      def export
        unit = "mg/dL"
        unit = "%{HemoglobinA1C}" if blood_sugar.blood_sugar_type_hba1c?

        FHIR::Observation.new(
          id: blood_sugar.id,
          identifier: [
            FHIR::Identifier.new(
              value: blood_sugar.id
            )
          ],
          code: FHIR::CodeableConcept.new(
            coding: FHIR::Coding.new(
              system: "http://snomed.info/sct",
              code: blood_sugar_type_code
            )
          ),
          valueQuantity: FHIR::Quantity.new(
            value: blood_sugar.blood_sugar_value,
            unit: unit,
            system: "http://unitsofmeasure.org",
            code: unit
          ),
          effectiveDateTime: blood_sugar.recorded_at.iso8601,
          status: "final",
          subject: FHIR::Reference.new(
            reference: "Patient/#{blood_sugar.patient_id}"
          ),
          performer: FHIR::Reference.new(
            reference: "Practitioner/#{opensrp_ids[:practitioner_id]}"
          ),
          encounter: FHIR::Reference.new(
            reference: "Encounter/#{encounter_id}"
          ),
          meta: meta
        )
      end

      def export_no_diabetes_observation
        FHIR::Observation.new(
          meta: meta,
          code: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "https://smartregister.org",
                code: "no_diabetes",
                display: "No Diabetes"
              )
            ]
          ),
          subject: FHIR::Reference.new(
            reference: "Patient/#{patient.id}"
          ),
          performer: FHIR::Reference.new(
            reference: "Practitioner/#{opensrp_ids[:practitioner_id]}"
          ),
          encounter: FHIR::Reference.new(
            reference: "Encounter/#{encounter_id}"
          )
        )
      end

      def blood_sugar_type_code
        case blood_sugar.blood_sugar_type
        when "random" then "271061004"
        when "post_prandial" then "372661000119106"
        when "fasting" then "271062006"
        when "hba1c" then "443911005"
        else raise "Invalid blood sugar type: #{blood_sugar.blood_sugar_type}"
        end
      end

      def export_encounter
        {
          parent_id: parent_encounter_id,
          encounter_opensrp_ids: opensrp_ids,
          child_encounter: FHIR::Encounter.new(
            meta: meta,
            status: "finished",
            id: encounter_id,
            identifier: [
              FHIR::Identifier.new(
                value: encounter_id
              )
            ],
            class: FHIR::Coding.new(
              system: "http://terminology.hl7.org/CodeSystem/v3-ActCode",
              code: "AMB"
            ),
            type: [
              FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "https://smartregister.org",
                    code: "facility_visit"
                  )
                ]
              )
            ],
            serviceType: FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://terminology.hl7.org/CodeSystem/service-type",
                  code: "335"
                )
              ]
            ),
            subject: FHIR::Reference.new(reference: "Patient/#{blood_sugar.patient_id}"),
            period: FHIR::Period.new(
              start: blood_sugar.recorded_at.iso8601,
              end: blood_sugar.recorded_at.iso8601
            ),
            reasonCode: [
              FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "https://smartregister.org",
                    code: "glucose_measure"
                  )
                ]
              )
            ],
            diagnosis: nil,
            location: nil,
            serviceProvider: FHIR::Reference.new(reference: "Organization/#{opensrp_ids[:organization_id]}"),
            partOf: FHIR::Reference.new(reference: "Encounter/#{parent_encounter_id}")
          )
        }
      end

      def parent_encounter_id
        "patient-visit-#{meta.lastUpdated.to_date.iso8601}-#{blood_sugar.patient_id}"
      end

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, blood_sugar&.id || "no_diabetes_#{patient.id}")
      end

      def meta
        FHIR::Meta.new(
          lastUpdated: blood_sugar&.device_updated_at&.iso8601 || patient.device_updated_at.iso8601,
          tag: [
            FHIR::Coding.new(
              system: "https://smartregister.org/app-version",
              code: "Not defined",
              display: "Application Version"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/location-tag-id",
              code: opensrp_ids[:location_id],
              display: "Practitioner Location"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/organisation-tag-id",
              code: opensrp_ids[:organization_id],
              display: "Practitioner Organization"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: opensrp_ids[:care_team_id],
              display: "Practitioner CareTeam"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: opensrp_ids[:practitioner_id],
              display: "Practitioner"
            )
          ]
        )
      end

      private

      attr_reader :opensrp_ids
    end
  end
end
