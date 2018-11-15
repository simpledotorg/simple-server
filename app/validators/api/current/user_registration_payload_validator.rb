class Api::Current::UserRegistrationPayloadValidator < Api::Current::PayloadValidator

  attr_accessor(
    :id,
    :full_name,
    :phone_number,
    :password_digest,
    :facility_ids,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::Current::Models.user
  end

  def errors_hash
    errors.to_hash
  end
end