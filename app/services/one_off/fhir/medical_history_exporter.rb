require "fhir_models"

module OneOff
  module Fhir
    class MedicalHistoryExporter
      attr_reader :medical_history
      DM_CONDITION_CODE = "73211009"
      HTN_CONDITION_CODE = "38341003"

      def initialize(medical_history)
        @medical_history = medical_history
      end

      def export
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
            id: FHIR::Patient.new(
              identifier: FHIR::Identifier.new(
                value: medical_history.patient_id
              )
            )
          ),
          code: [
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: condition_code
                )
              ]
            )
          ],
          meta: FHIR::Meta.new(
            lastUpdated: medical_history.device_updated_at.iso8601,
            createdAt: medical_history.device_created_at.iso8601
          )
        )
      end
    end
  end
end
