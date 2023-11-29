require "fhir_models"

module OneOff
  module Fhir
    class AppointmentExporter
      attr_reader :appointment

      def initialize(appointment)
        @appointment = appointment
      end

      def export
        FHIR::Appointment.new(
          status: appointment_status_code,
          start: appointment.scheduled_date.beginning_of_day.iso8601,
          cancellationReason: cancellation_code,
          participant: [
            FHIR::Appointment::Participant.new(
              actor: FHIR::Reference.new(
                id: FHIR::Patient.new(
                  identifier: FHIR::Identifier.new(
                    value: appointment.patient_id
                  )
                )
              )
            )
          ],
          identifier: [
            FHIR::Identifier.new(
              value: appointment.id.to_s
            )
          ],
          meta: FHIR::Meta.new(
            lastUpdated: appointment.device_updated_at.iso8601,
            createdAt: appointment.device_created_at.iso8601
          )
        )
      end

      def cancellation_code
        case appointment.cancel_reason
        when "dead" then "pat-dec"
        else "pat"
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
    end
  end
end
