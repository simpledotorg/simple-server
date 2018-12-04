class Api::Current::CommunicationsController < Api::Current::SyncController
  def sync_from_user
    __sync_from_user__(communications_params)
  end

  def sync_to_user
    __sync_to_user__('communications')
  end

  private

  def current_facility_records
    Communication.where(appointment: Appointment.where(facility: current_facility.appointments))
      .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.count
    Communication.where(appointment: Appointment.where(facility: current_user.facilities_in_group_other_than(current_facility)))
      .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end

  def merge_if_valid(communication_params)
    validator = Api::Current::CommunicationPayloadValidator.new(communication_params)
    logger.debug "Follow Up  had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/Communication/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      communication = Communication.merge(Api::Current::Transformer.from_request(communication_params))
      { record: communication }
    end
  end

  def transform_to_response(communication)
    Api::Current::Transformer.to_response(communication)
  end

  def communications_params
    params.require(:communications).map do |communication_params|
      communication_params.permit(
        :id,
        :appointment_id,
        :user_id,
        :communication_type,
        :communication_result,
        :created_at,
        :updated_at)
    end
  end
end
