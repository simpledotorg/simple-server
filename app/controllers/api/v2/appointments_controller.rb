class Api::V2::AppointmentsController < Api::Current::AppointmentsController
  private

  def set_default_appointment_type(appointment_params)
    if !appointment_params.key?('appointment_type') && Appointment.compute_merge_status(appointment_params) == :new
      appointment_params['appointment_type'] = Appointment.appointment_types[:manual]
    end
  end

  def merge_if_valid(appointment_params)
    validator = Api::V2::AppointmentPayloadValidator.new(appointment_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Appointment/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      record_params = Api::V2::AppointmentTransformer.from_request(appointment_params)
      set_default_appointment_type(record_params)
      appointment = Appointment.merge(record_params)
      { record: appointment }
    end
  end

  def transform_to_response(appointment)
    Api::V2::AppointmentTransformer.to_response(appointment)
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
