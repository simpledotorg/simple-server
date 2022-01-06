# frozen_string_literal: true

class Api::V3::CommunicationPayloadValidator < Api::V3::PayloadValidator
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
    Api::V3::Models.communication
  end
end
