module Api
  module V3
    module Historical
      class AppointmentsController < HistoricalSyncController
        def sync_from_user
          __sync_from_user__(appointments_params)
        end

        def sync_to_user
          __sync_to_user__("appointments")
        end

        def metadata
          {user_id: current_user.id}
        end

        private

        def merge_if_valid(appointment_params)
          record_params = Api::V3::AppointmentTransformer
            .from_request(appointment_params)
            .merge(metadata)

          appointment = Appointment.find_or_initialize_by(id: record_params[:id])
          safe_assign_attributes(appointment, record_params)

          if appointment.save(validate: false)
            begin
              appointment.update_patient_status
            rescue => e
              Rails.logger.info "Error updating patient status: #{e.message}"
            end

            {record: appointment}
          else
            {
              errors_hash: {
                id: record_params[:id],
                error_type: "save_failed",
                message: appointment.errors.full_messages.join(", ")
              }
            }
          end
        end

        def transform_to_response(appointment)
          Api::V3::AppointmentTransformer.to_response(appointment)
        end

        def appointments_params
          params.require(:appointments).map do |appointment_params|
            appointment_params.permit(
              :id,
              :patient_id,
              :facility_id,
              :creation_facility_id,
              :scheduled_date,
              :status,
              :cancel_reason,
              :remind_on,
              :agreed_to_visit,
              :appointment_type,
              :created_at,
              :updated_at
            )
          end
        end
      end
    end
  end
end
