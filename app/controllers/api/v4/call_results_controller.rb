class Api::V4::CallResultsController < Api::V4::SyncController
  def sync_from_user
    __sync_from_user__(call_result_params)
  end

  private

  def merge_if_valid(call_result_params)
    validator = Api::V4::CallResultPayloadValidator.new(call_result_params)
    logger.debug "CallResult had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      transformed_params = Api::V4::Transformer.from_request(call_result_params)
      call_result = CallResult.merge(transformed_params)

      {record: call_result}
    end
  end

  def call_result_params
    params.require(:call_results).map do |call_result_params|
      call_result_params.permit(
        :id,
        :user_id,
        :patient_id,
        :facility_id,
        :appointment_id,
        :remove_reason,
        :result_type,
        :deleted_at,
        :created_at,
        :updated_at
      )
    end
  end
end
