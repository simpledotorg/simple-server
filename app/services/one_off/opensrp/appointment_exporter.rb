require "fhir_models"

module OneOff
  module Opensrp
    class AppointmentExporter
      attr_reader :appointment

      def initialize(appointment, opensrp_mapping)
        @appointment = appointment
        @opensrp_ids = opensrp_mapping[@appointment.facility_id]
      end

      def export
        FHIR::Appointment.new(
          meta: meta,
          status: appointment_status_code,
          start: appointment.scheduled_date.beginning_of_day.iso8601,
          created: appointment.device_created_at.iso8601,
          serviceType: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://terminology.hl7.org/CodeSystem/service-type",
                code: "335"
              )
            ]
          ),
          appointmentType: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "https://terminology.hl7.org/3.1.0/CodeSystem-v2-0276.html",
                code: "FOLLOWUP"
              )
            ]
          ),
          reasonCode: [
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://snomed.info/sct",
                  code: "1156892006"
                )
              ]
            )
          ],
          participant: [
            FHIR::Appointment::Participant.new(
              actor: FHIR::Reference.new(reference: "Patient/#{appointment.patient_id}"),
              status: participant_status
            ),
            FHIR::Appointment::Participant.new(
              actor: FHIR::Reference.new(reference: "Practitioner/#{opensrp_ids[:practitioner_id]}"),
              status: participant_status
            )
          ],
          id: appointment.id,
          identifier: [
            FHIR::Identifier.new(
              value: appointment.id
            )
          ]
        )
      end

      def export_encounter
        {
          parent_id: parent_encounter_id,
          encounter_opensrp_ids: opensrp_ids,
          child_encounter: FHIR::Encounter.new(
            meta: meta,
            status: encounter_status_code,
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
                  system: "https://terminology.hl7.org/3.1.0/CodeSystem-v2-0276.html",
                  code: "FOLLOWUP"
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
            subject: FHIR::Reference.new(reference: "Patient/#{appointment.patient_id}"),
            appointment: FHIR::Reference.new(reference: "Appointment/#{appointment.id}"),
            period: FHIR::Period.new(start: appointment.scheduled_date.iso8601, end: appointment.scheduled_date.iso8601),
            reasonCode: [
              FHIR::CodeableConcept.new(
                coding: [
                  FHIR::Coding.new(
                    system: "http://snomed.info/sct",
                    code: "1156892006"
                  )
                ]
              )
            ],
            diagnosis: nil,
            location: nil,
            serviceProvider: FHIR::Reference.new(reference: "Organization/#{appointment.facility_id}"),
            partOf: FHIR::Reference.new(reference: "Encounter/#{parent_encounter_id}")
          )
        }
      end

      def encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, appointment.id)
      end

      def parent_encounter_id
        Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, appointment.patient_id + meta.lastUpdated.to_date.iso8601)
      end

      def participant_status
        case appointment.agreed_to_visit
        when true then "accepted"
        when false then "declined"
        else "needs-action"
        end
      end

      def appointment_status_code
        case appointment.status
        when "scheduled" then "booked"
        when "visited" then "fulfilled"
        when "cancelled" then "cancelled"
        else raise "Invalid appointment status: #{appointment.status}"
        end
      end

      def encounter_status_code
        case appointment.status
        when "scheduled" then "planned"
        when "visited" then "finished"
        when "cancelled" then "cancelled"
        else raise "Invalid appointment status: #{appointment.status}"
        end
      end

      def meta
        FHIR::Meta.new(
          lastUpdated: appointment.device_updated_at.iso8601,
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
