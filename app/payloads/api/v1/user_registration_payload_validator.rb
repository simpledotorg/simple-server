class Api::V1::UserRegistrationPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :full_name,
    :phone_number,
    :password,
    :password_confirmation,
    :facility_id,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.register_user
  end

  def errors_hash
    errors.to_hash
  end
end