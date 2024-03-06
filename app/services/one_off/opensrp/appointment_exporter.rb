require "fhir_models"

module OneOff
  module Opensrp
    class AppointmentExporter
      attr_reader :appointment

      def initialize(appointment)
        @appointment = appointment
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
          participant: [
            FHIR::Appointment::Participant.new(
              actor: FHIR::Reference.new(reference: "Patient/#{appointment.patient_id}"),
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
        FHIR::Encounter.new(
          meta: meta,
          status: encounter_status_code,
          id: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, appointment.id),
          identifier: [
            FHIR::Identifier.new(
              value: Digest::UUID.uuid_v5(Digest::UUID::DNS_NAMESPACE, appointment.id)
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
          period: FHIR::Period.new(start: appointment.scheduled_date.iso8601), # TODO: we don't store end period
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
          partOf: nil
        )
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
            )
          ]
        )
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
        when "scheduled" then "pending"
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
    end
  end
end
