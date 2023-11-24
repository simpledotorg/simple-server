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
          code: [
            FHIR::CodeableConcept.new(
              coding: FHIR::Coding.new(
                system: "http://lonic.com/",
                code: bs_type_loinc_code,
                display: blood_sugar.blood_sugar_type
              )
            )
          ],
          valueQuantity: FHIR::Quantity.new(
            value: blood_sugar.blood_sugar_value,
            unit: "mg/dL",
            system: "http://unitsofmeasure.org",
            code: "mg/dL"
          ),
          subject: FHIR::Reference.new(
            reference: FHIR::Patient.new(
              identifier: FHIR::Identifier.new(
                value: blood_sugar.patient_id
              )
            )
          ),
          performer: FHIR::Reference.new(
            reference: FHIR::Organization.new(
              identifier: FHIR::Identifier.new(
                value: blood_sugar.facility_id
              )
            )
          ),
          meta: FHIR::Meta.new(
            lastUpdated: blood_sugar.device_updated_at,
            createdAt: blood_sugar.recorded_at
          )
        )
      end

      def bs_type_loinc_code
        case blood_sugar.blood_sugar_type
        when "random" then "2339-0"
        when "post_prandial" then "123"
        when "fasting" then "123"
        when "hba1c" then "123"
        else "123"
        end
      end
    end
  end
end
