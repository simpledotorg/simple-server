require "fhir_models"

module OneOff
  module Fhir
    class BloodSugarExporter
      attr_reader :blood_sugar

      def initialize(blood_sugar)
        @blood_sugar = blood_sugar
      end

      def export
        FHIR::Observation.new(
          identifier: [
            FHIR::Identifier.new(
              value: blood_sugar.id.to_s
            )
          ],
          component: [
            observation_component(bs_type_loinc_code, blood_sugar.blood_sugar_value)
          ],
          subject: FHIR::Reference.new(
            reference: FHIR::Patient.new(
              id: blood_pressure.patient_id
            )
          ),
          meta: FHIR::Meta.new(
            lastUpdated: patient.updated_at,
            createdAt: patient.recorded_at
          )
        # TODO: Add facility id
        )
      end

      def bs_type_loinc_code
        case blood_sugar.blood_sugar_type
        when "random" then "2339-0"
        when "post_prandial" then ""
        when "fasting" then ""
        when "hba1c" then ""
        else ""
        end
      end

      def observation_component(code, value)
        FHIR::ObservationComponent.new(
          code: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://loinc.org",
                code: code
              )
            ],
            value_quantity: FHIR::Quantity.new(
              value: value,
              unit: "mg/dL",
              system: "http://unitsofmeasure.org",
              code: "mg/dL"
            )
          )
        )
      end
    end
  end
end
