class Api::V1::AppointmentsController < Api::V2::AppointmentsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  private

  def merge_if_valid(appointment_params)
    validator = Api::V1::AppointmentPayloadValidator.new(appointment_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    record_params = Api::V1::Transformer.from_request(appointment_params)
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Appointment/schema_invalid')
      { errors_hash: validator.errors_hash }
    elsif record_params[:status] == 'cancelled' and Appointment.compute_merge_status(record_params) == :updated
      NewRelic::Agent.increment_metric('Merge/Appointment/invalid_request')
      { errors_hash: { updated_at: 'Cancelled appointment cannot be updated', id: appointment_params[:id] } }
    else
      set_default_appointment_type(record_params)
      appointment = Appointment.merge(record_params)
      { record: appointment }
    end
  end

  def transform_to_response(appointment)
    Api::V1::AppointmentTransformer.to_response(appointment)
  end
end
