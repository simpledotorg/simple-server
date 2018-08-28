class Api::V1::CommunicationPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :appointment_id,
    :user_id,
    :communication_type,
    :communication_result,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.communication
  end
end
