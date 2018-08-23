class Api::V1::FollowUpSchedulePayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :patient_id,
    :facility_id,
    :next_visit,
    :action_by_user_id,
    :user_action,
    :reason_for_action,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.follow_up_schedule
  end
end
