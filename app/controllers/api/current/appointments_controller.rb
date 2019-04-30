class Api::Current::AppointmentsController < Api::Current::SyncController
  include Api::Current::PrioritisableByFacility

  def sync_from_user
    __sync_from_user__(appointments_params)
  end

  def sync_to_user
    __sync_to_user__('appointments')
  end

  def set_default_appointment_type(appointment_params)
    if !appointment_params.key?('appointment_type') && Appointment.compute_merge_status(appointment_params) == :new
      appointment_params['appointment_type'] = Appointment.appointment_types[:manual]
    end
  end

  private

  def merge_if_valid(appointment_params)
    validator = Api::Current::AppointmentPayloadValidator.new(appointment_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Appointment/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      record_params = Api::Current::Transformer.from_request(appointment_params)
      set_default_appointment_type(record_params)
      appointment = Appointment.merge(record_params)
      { record: appointment }
    end
  end

  def transform_to_response(appointment)
    Api::Current::Transformer.to_response(appointment)
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
        :appointment_type,
        :created_at,
        :updated_at)
    end
  end
end
