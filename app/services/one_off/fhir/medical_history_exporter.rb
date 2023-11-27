require "fhir_models"

module OneOff
  module Fhir
    class MedicalHistoryExporter
      attr_reader :medical_history
      DM_CONDITION_CODE = 123
      HTN_CONDITION_CODE = 123

      def initialize(medical_history)
        @medical_history = medical_history
      end

      def export
        fhir_resource.map(&:to_json)
      end

      def fhir_resource
        conditions = []
        if medical_history.diabetes == "yes"
          conditions << generate_condition(DM_CONDITION_CODE)
        end
        if medical_history.hypertension == "yes"
          conditions << generate_condition(HTN_CONDITION_CODE)
        end
        conditions
      end

      def generate_condition(condition_code)
        FHIR::Condition.new(
          subject: FHIR::Reference.new(
            reference: FHIR::Patient.new(
              identifier: FHIR::Identifier.new(
                value: medical_history.patient_id
              )
            )
          ),
          code: [
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://loinc.org",
                  code: condition_code
                )
              ]
            )
          ],
          meta: FHIR::Meta.new(
            lastUpdated: medical_history.device_updated_at,
            createdAt: medical_history.device_created_at
          )
        )
      end
    end
  end
end
