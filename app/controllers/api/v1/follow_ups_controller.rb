class Api::V1::FollowUpsController < Api::V1::SyncController
  def sync_from_user
    __sync_from_user__(follow_ups_params)
  end

  def sync_to_user
    __sync_to_user__('follow_ups')
  end

  private

  def merge_if_valid(follow_up_params)
    validator = Api::V1::FollowUpPayloadValidator.new(follow_up_params)
    logger.debug "Follow Up  had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/FollowUp/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      follow_up = FollowUp.merge(Api::V1::Transformer.from_request(follow_up_params))
      { record: follow_up }
    end
  end

  def find_records_to_sync(since, limit)
    FollowUp.updated_on_server_since(since, limit)
  end

  def transform_to_response(follow_up)
    Api::V1::Transformer.to_response(follow_up)
  end

  def follow_ups_params
    params.require(:follow_ups).map do |follow_up_params|
      follow_up_params.permit(
        :id,
        :follow_up_schedule_id,
        :user_id,
        :follow_up_type,
        :follow_up_result,
        :created_at,
        :updated_at)
    end
  end
end
