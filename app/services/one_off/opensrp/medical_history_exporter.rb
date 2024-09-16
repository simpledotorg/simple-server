require "fhir_models"

module OneOff
  module Opensrp
    class MedicalHistoryExporter
      attr_reader :medical_history

      DM_CONDITION_MAPPING = {code: "diabetes", system: "https://smartregister.org", display: "Diabetes"}
      HTN_CONDITION_MAPPING = {code: "38341003", system: "http://snomed.info/sct", display: "Hypertension"}

      def initialize(medical_history, opensrp_mapping)
        @medical_history = medical_history
        @opensrp_ids = opensrp_mapping[@medical_history.patient.assigned_facility_id]
      end

      def export
        conditions = []
        conditions << generate_condition(DM_CONDITION_MAPPING) if medical_history.diabetes_yes?
        conditions << generate_condition(HTN_CONDITION_MAPPING) if medical_history.hypertension_yes?
        conditions
      end

      def generate_condition(code:, display:, system:)
        FHIR::Condition.new(
          id: condition_id(code),
          subject: FHIR::Reference.new(
            reference: "Patient/#{medical_history.patient_id}"
          ),
          code: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                code: code,
                system: system,
                display: display
              )
            ],
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
        codes = [
          (HTN_CONDITION_MAPPING[:code] if medical_history.hypertension_yes?),
          (DM_CONDITION_MAPPING[:code] if medical_history.diabetes_yes?)
        ].compact
        generate_export_encounter(codes) if codes.present?
      end

      def generate_export_encounter(codes)
        {
          parent_id: parent_encounter_id,
          encounter_opensrp_ids: opensrp_ids,
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
            period: FHIR::Period.new(
              start: medical_history.device_updated_at.iso8601,
              end: medical_history.device_updated_at.iso8601
            ),
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
            diagnosis: codes.map { |code| FHIR::Reference.new(reference: "Condition/#{condition_id(code)}") },
            location: nil,
            serviceProvider: FHIR::Reference.new(reference: "Organization/#{opensrp_ids[:organization_id]}"),
            partOf: FHIR::Reference.new(reference: "Encounter/#{parent_encounter_id}")
          )
        }
      end

      def condition_id(code)
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, medical_history.id + "_" + code)
      end

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, medical_history.id)
      end

      def parent_encounter_id
        "patient-visit-#{meta.lastUpdated.to_date.iso8601}-#{medical_history.patient_id}"
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
              code: opensrp_ids[:location_id],
              display: "Practitioner Location"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/organisation-tag-id",
              code: opensrp_ids[:organization_id],
              display: "Practitioner Organization"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: opensrp_ids[:care_team_id],
              display: "Practitioner CareTeam"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: opensrp_ids[:practitioner_id],
              display: "Practitioner"
            )
          ]
        )
      end

      private

      attr_reader :opensrp_ids
    end
  end
end
