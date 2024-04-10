require "fhir_models"

module OneOff
  module Opensrp
    class MedicalHistoryExporter
      attr_reader :medical_history
      DM_CONDITION_MAPPING = {code: "44054006", display: "Diabetes mellitus type 2"}
      HTN_CONDITION_MAPPING = {code: "38341003", display: "Hypertension"}

      def initialize(medical_history)
        @medical_history = medical_history
      end

      def export
        conditions = []
        conditions << generate_condition(DM_CONDITION_MAPPING) if medical_history.diabetes_yes?
        conditions << generate_condition(HTN_CONDITION_MAPPING) if medical_history.hypertension_yes?
        conditions
      end

      def generate_condition(code:, display:)
        FHIR::Condition.new(
          id: medical_history.id,
          subject: FHIR::Reference.new(
            reference: "Patient/#{medical_history.patient_id}"
          ),
          code: FHIR::Code.new(
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: code,
                  display: display
                )
              ]
            ),
            text: display
          ),
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
          encounter: FHIR::Reference.new(
            reference: "Encounter/#{encounter_id}"
          ),
          meta: meta
        )
      end

      def export_encounter
        {
          parent_encounter_id: parent_encounter_id,
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
        }
      end

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, medical_history.id)
      end

      def parent_encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, medical_history.patient_id + meta.lastUpdated.to_date.iso8601)
      end

      def meta
        FHIR::Meta.new(
          lastUpdated: medical_history.device_updated_at.iso8601,
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
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/related-entity-location-tag-id",
              code: "TODO", # TODO
              display: "Related Entity Location"
            )
          ]
        )
      end
    end
  end
end
