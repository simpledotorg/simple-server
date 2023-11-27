require "fhir_models"

module OneOff
  module Fhir
    class AppointmentExporter
      attr_reader :appointment

      def initialize(appointment)
        @appointment = appointment
      end

      def export
        fhir_resource.to_json
      end

      def fhir_resource
        FHIR::Appointment.new(
          status: appointment.status,
          start: appointment.scheduled_date,
          cancellationReason: get_cancellation_code,
          participant: [FHIR::Appointment::Participant.new(
            actor: FHIR::Reference.new(
              reference: FHIR::Patient.new(
                identifier: FHIR::Identifier.new(
                  value: appointment.patient_id
                )
              )
            )
          )],
          identifier: [
            FHIR::Identifier.new(
              value: appointment.id.to_s
            )
          ],
          meta: FHIR::Meta.new(
            lastUpdated: appointment.device_updated_at,
            createdAt: appointment.device_created_at
          )
        )
      end

      def get_cancellation_code
        case appointment.cancel_reason
        when "dead" then "pat-dec"
        else "pat"
        end
      end
    end
  end
end
