require "fhir_models"

module OneOff
  module Opensrp
    class BloodSugarExporter
      attr_reader :blood_sugar

      def initialize(blood_sugar)
        @blood_sugar = blood_sugar
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
            reference: "Organization/#{blood_sugar.facility_id}"
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
        FHIR::Encounter.new(
          meta: meta,
          status: "finished",
          id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, blood_sugar.id),
          identifier: [
            FHIR::Identifier.new(
              value: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, blood_sugar.id)
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
          serviceProvider: FHIR::Reference.new(reference: "Organization/#{blood_sugar.facility_id}"),
          partOf: nil
        )
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
              code: "TODO", # TODO
              display: "Practitioner Location"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/organisation-tag-id",
              code: "TODO", # TODO
              display: "Practitioner Organization"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: "TODO", # TODO
              display: "Practitioner CareTeam"
            )
          ]
        )
      end
    end
  end
end
