require "fhir_models"

module OneOff
  module Opensrp
    class BloodSugarExporter
      attr_reader :blood_sugar

      def initialize(blood_sugar, opensrp_mapping)
        @blood_sugar = blood_sugar
        @opensrp_ids = opensrp_mapping[@blood_sugar.facility_id]
      end

      def export
        unit = "mg/dL"
        unit = "%{HemoglobinA1C}" if blood_sugar.blood_sugar_type_hba1c?

        FHIR::Observation.new(
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
          meta: FHIR::Meta.new(
            lastUpdated: blood_sugar.device_updated_at.iso8601,
            createdAt: blood_sugar.recorded_at.iso8601
          )
        )
      end

      def blood_sugar_type_code
        case blood_sugar.blood_sugar_type
        when "random" then "271061004"
        when "post_prandial" then "TODO"
        when "fasting" then "365757006"
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
                coding: FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: "44054006"
                )
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
            period: FHIR::Period.new(start: blood_sugar.recorded_at.iso8601), # TODO: we don't store end period
            reasonCode: [
              FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "http://snomed.info/sct",
                    code: "1156892006" # TODO
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

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, blood_sugar.patient_id + meta.lastUpdated.to_date.iso8601)
      end

      def parent_encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, blood_sugar.id)
      end

      def meta
        FHIR::Meta.new(
          lastUpdated: blood_sugar.device_updated_at.iso8601,
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
