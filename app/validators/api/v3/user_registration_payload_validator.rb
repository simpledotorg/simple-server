# frozen_string_literal: true

class Api::V3::UserRegistrationPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :full_name,
    :phone_number,
    :password_digest,
    :registration_facility_id,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def schema
    Api::V3::Models.user
  end

  def errors_hash
    errors.to_hash
  end
end
