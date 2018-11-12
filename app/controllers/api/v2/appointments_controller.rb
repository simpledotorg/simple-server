class Api::V2::AppointmentsController < Api::SyncController
  def sync_from_user
    __sync_from_user__(appointments_params)
  end

  def sync_to_user
    __sync_to_user__('appointments')
  end

  private

  def merge_if_valid(appointment_params)
    validator = Api::V1::AppointmentPayloadValidator.new(appointment_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Appointment/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      appointment = Appointment.merge(Api::V1::Transformer.from_request(appointment_params))
      { record: appointment }
    end
  end

  def find_records_to_sync(since, limit)
    Appointment.updated_on_server_since(since, limit)
  end

  def transform_to_response(appointment)
    Api::V1::Transformer.to_response(appointment)
  end

  def appointments_params
    params.require(:appointments).map do |appointment_params|
      appointment_params.permit(
        :id,
        :patient_id,
        :facility_id,
        :scheduled_date,
        :status,
        :cancel_reason,
        :remind_on,
        :agreed_to_visit,
        :created_at,
        :updated_at)
    end
  end
end
