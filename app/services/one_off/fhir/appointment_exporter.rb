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
          participant: [
            FHIR::Appointment::Participant.new(
              actor: FHIR::Reference.new(
                id: FHIR::Patient.new(
                  identifier: FHIR::Identifier.new(
                    value: appointment.patient_id
                  )
                )
              ),
              status: participant_status
            )
          ],
          identifier: [
            FHIR::Identifier.new(
              value: appointment.id
            )
          ],
          meta: FHIR::Meta.new(
            lastUpdated: appointment.device_updated_at.iso8601,
            createdAt: appointment.device_created_at.iso8601
          )
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
    end
  end
end
