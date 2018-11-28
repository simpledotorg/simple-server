class Api::Current::CommunicationPayloadValidator < Api::Current::PayloadValidator

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
    Api::Current::Models.communication
  end
end
