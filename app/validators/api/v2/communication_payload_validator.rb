class Api::V2::CommunicationPayloadValidator < Api::V3::CommunicationPayloadValidator
  attr_accessor(
    :id,
    :appointment_id,
    :user_id,
    :communication_type,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V2::Models.communication
  end
end
