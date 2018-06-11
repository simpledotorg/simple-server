class Api::V1::UserPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :id,
    :created_at,
    :updated_at,
    :full_name,
    :phone_number,
    :security_pin_hash,
    :facility_id
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.user
  end
end
