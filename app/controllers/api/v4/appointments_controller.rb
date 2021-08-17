class Api::V4::AppointmentsController < Api::V4::SyncController
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
    validator = Api::V3::AppointmentPayloadValidator.new(appointment_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      record_params = Api::V3::AppointmentTransformer
                        .from_request(appointment_params)
                        .merge(metadata)

      appointment = Appointment.merge(record_params)
      appointment.update_patient_status
      {record: appointment}
    end
  end

  def transform_to_response(appointment)
    Api::V3::AppointmentTransformer.to_response(appointment)
  end

  def appointments_params
    permitted_call_result_params = %i[
      id,
      user_id,
      cancel_reason,
      agreed_to_visit,
      remind_on,
      created_at,
      updated_at,
      deleted_at
    ]

    params.require(:appointments).map do |appointment_params|
      appointment_params.permit(
        :id,
        :patient_id,
        :facility_id,
        :creation_facility_id,
        :scheduled_date,
        :status,
        :appointment_type,
        :created_at,
        :updated_at,
        call_results: [permitted_call_result_params]
      )
    end
  end
end
