class Api::V1::UserRegistrationPayloadValidator < Api::V1::PayloadValidator
  attr_accessor(
    :id,
    :full_name,
    :phone_number,
    :password_digest,
    :facility_ids,
    :created_at,
    :updated_at
  )

  def schema
    Api::V1::Models.user
  end

  def errors_hash
    errors.to_hash
  end
end
