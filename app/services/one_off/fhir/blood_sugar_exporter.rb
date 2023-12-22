require "fhir_models"

module OneOff
  module Fhir
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
              system: "http://loinc.org/",
              code: "2339-0"
            )
          ),
          component: [
            FHIR::Observation::Component.new(
              code: FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "http://loinc.org",
                    code: blood_sugar_type_code
                  )
                ]
              ),
              valueQuantity: FHIR::Quantity.new(
                value: blood_sugar.blood_sugar_value,
                unit: unit,
                system: "http://unitsofmeasure.org",
                code: unit
              )
            )
          ],
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
    end
  end
end
