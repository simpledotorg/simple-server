require "fhir_models"

module OneOff
  module Opensrp
    class EncounterGenerator
      attr_reader :encounters

      def initialize(encounters)
        @encounters = encounters
      end

      def export_deduplicated
        encounters.group_by(&:parent_id).map do |parent_id, child_encounters|
          child_encounters.map(&:child_encounter).append(
            FHIR::Encounter.new(
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
              subject: FHIR::Reference.new(reference: "Patient/#{medical_history.patient_id}"),
              period: FHIR::Period.new(start: medical_history.device_updated_at.iso8601), # TODO: we don't store end period
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
              diagnosis: FHIR::Reference.new(reference: "Condition/#{medical_history.id}"),
              location: nil,
              serviceProvider: FHIR::Reference.new(reference: "Organization/#{medical_history.patient.assigned_facility_id}"),
              partOf: FHIR::Reference.new(reference: "Encounter/#{parent_encounter_id}")
            )
          )
        end
      end
    end
  end
end
