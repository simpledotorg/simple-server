require "fhir_models"

module OneOff
  module Fhir
    class MedicalHistoryExporter
      attr_reader :medical_history
      DM_CONDITION_CODE = "44054006"
      HTN_CONDITION_CODE = "38341003"

      def initialize(medical_history)
        @medical_history = medical_history
      end

      def export
        conditions = []
        conditions << generate_condition(DM_CONDITION_CODE) if medical_history.diabetes_yes?
        conditions << generate_condition(HTN_CONDITION_CODE) if medical_history.hypertension_yes?
        conditions
      end

      def generate_condition(condition_code)
        FHIR::Condition.new(
          subject: FHIR::Reference.new(
            identifier: FHIR::Identifier.new(
              value: medical_history.patient_id
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
          clinicalStatus: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://terminology.hl7.org/CodeSystem/condition-clinical",
                code: "active"
              )
            ]
          ),
          verificationStatus: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                code: "confirmed"
              )
            ]
          ),
          meta: FHIR::Meta.new(
            lastUpdated: medical_history.device_updated_at.iso8601
          )
        )
      end
    end
  end
end
