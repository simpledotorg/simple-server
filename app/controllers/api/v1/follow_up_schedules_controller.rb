class Api::V1::FollowUpSchedulesController < Api::V1::SyncController
  def sync_from_user
    __sync_from_user__(follow_up_schedules_params)
  end

  def sync_to_user
    __sync_to_user__('follow_up_schedules')
  end

  private

  def merge_if_valid(follow_up_schedule_params)
    validator = Api::V1::FollowUpSchedulePayloadValidator.new(follow_up_schedule_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/FollowUpSchedule/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      follow_up_schedule = FollowUpSchedule.merge(Api::V1::Transformer.from_request(follow_up_schedule_params))
      { record: follow_up_schedule }
    end
  end

  def find_records_to_sync(since, limit)
    FollowUpSchedule.updated_on_server_since(since, limit)
  end

  def transform_to_response(follow_up_schedule)
    Api::V1::Transformer.to_response(follow_up_schedule)
  end

  def follow_up_schedules_params
    params.require(:follow_up_schedules).map do |follow_up_schedule_params|
      follow_up_schedule_params.permit(
        :id,
        :patient_id,
        :facility_id,
        :next_visit,
        :action_by_user_id,
        :user_action,
        :reason_for_action,
        :created_at,
        :updated_at)
    end
  end
end
