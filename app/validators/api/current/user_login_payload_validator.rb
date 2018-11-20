class Api::Current::UserLoginPayloadValidator < Api::Current::PayloadValidator

  attr_accessor(
    :phone_number,
    :password,
    :otp
  )

  validate :validate_schema

  def schema
    Api::Current::Models.login_user
  end
end
