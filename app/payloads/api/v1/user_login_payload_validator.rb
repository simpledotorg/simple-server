class Api::V1::UserLoginPayloadValidator < Api::V1::PayloadValidator

  attr_accessor(
    :phone_number,
    :password,
    :otp
  )

  validate :validate_schema

  def schema
    Api::V1::Schema::Models.login_user
  end
end
