# frozen_string_literal: true

class Api::V3::UserLoginPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :phone_number,
    :password,
    :otp
  )

  validate :validate_schema

  def schema
    Api::V3::Models.login_user
  end
end
