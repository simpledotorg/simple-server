class Api::V1::FollowUpPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :follow_up_schedule_id,
    :user_id,
    :follow_up_type,
    :follow_up_result,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.follow_up
  end
end
