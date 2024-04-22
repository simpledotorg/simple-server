require "fhir_models"

module OneOff
  module Opensrp
    class EncounterGenerator
      attr_reader :encounters

      def initialize(encounters)
        @encounters = encounters
      end

      def generate
        encounters.group_by { |encounter| encounter[:parent_id] }.tap { |x| p x.keys }.map do |parent_id, child_encounters|
          p parent_id
          p opensrp_ids = child_encounters.first[:encounter_opensrp_ids]
          first_child_encounter = child_encounters.first[:child_encounter]
          patient_ref = first_child_encounter.subject
          encounter_period = first_child_encounter.period
          diagnosis = first_child_encounter.diagnosis
          service_provider = first_child_encounter.serviceProvider
          child_encounters.pluck(:child_encounter).append(
            FHIR::Encounter.new(
              meta: meta(opensrp_ids),
              status: "finished",
              id: parent_id,
              identifier: [
                FHIR::Identifier.new(
                  value: parent_id
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
                    code: "185389009"
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
              subject: patient_ref,
              period: encounter_period, # TODO: we don't store end period
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
              diagnosis: diagnosis,
              location: nil,
              serviceProvider: service_provider,
              partOf: nil
            )
          )
        end
      end

      def meta(location_id:, organization_id:, care_team_id:, practitioner_id:, **)
        FHIR::Meta.new(
          lastUpdated: encounters.first[:child_encounter].meta.lastUpdated,
          tag: [
            FHIR::Coding.new(
              system: "https://smartregister.org/app-version",
              code: "Not defined",
              display: "Application Version"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/location-tag-id",
              code: location_id,
              display: "Practitioner Location"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/organisation-tag-id",
              code: organization_id,
              display: "Practitioner Organization"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: care_team_id,
              display: "Practitioner CareTeam"
            ),
            FHIR::Coding.new(
              system: "https://smartregister.org/care-team-tag-id",
              code: practitioner_id,
              display: "Practitioner"
            )
          ]
        )
      end
    end
  end
end
