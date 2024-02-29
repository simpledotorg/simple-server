require "fhir_models"

module OneOff
  module OpenSRP
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
              system: "TODO",
              code: "TODO" # blood_sugar_type_code
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
            identifier: FHIR::Identifier.new(
              value: blood_sugar.patient_id
            )
          ),
          performer: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: blood_sugar.facility_id
            )
          ),
          meta: FHIR::Meta.new(
            lastUpdated: blood_sugar.device_updated_at.iso8601,
            createdAt: blood_sugar.recorded_at.iso8601
          )
        )
      end

      def blood_sugar_type_code
        case blood_sugar.blood_sugar_type
        when "random" then "2339-0"
        when "post_prandial" then "87422-2"
        when "fasting" then "88365-2"
        when "hba1c" then "4548-4"
        else raise "Invalid blood sugar type: #{blood_sugar.blood_sugar_type}"
        end
      end

      def export_encounter
        FHIR::Encounter.new(
          meta: meta,
          status: encounter_status_code,
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
                system: "TODO",
                code: "TODO"
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
                  code: "TODO" # TODO
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
    end
  end
end
