class MasterUser < ApplicationRecord

  AUTHENTICATION_TYPES = {
    email_authentication: 'EmailAuthentication',
    phone_number_authentication: 'PhoneNumberAuthentication'
  }

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  has_many :user_authentications

  validates :full_name, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  def phone_number_authentication
    user_authentication_of_type(AUTHENTICATION_TYPES[:phone_number_authentication])
  end

  def registration_facility
    delegate_to_phone_number_authentication(:facility)
  end

  def access_token
    delegate_to_phone_number_authentication(:access_token)
  end

  def access_token_valid?
    self.sync_approval_status_allowed?
  end

  def logged_in_at
    delegate_to_phone_number_authentication(:logged_in_at)
  end

  def has_never_logged_in?
    delegate_to_phone_number_authentication(:has_never_logged_in?)
  end

  def mark_as_logged_in
    delegate_to_phone_number_authentication(:mark_as_logged_in)
  end

  private

  def delegate_to_phone_number_authentication(method)
    return nil unless phone_number_authentication.present?
    phone_number_authentication.send(method)
  end

  def user_authentication_of_type(authenticatable_type)
    user_authentications.find_by(authenticatable_type: authenticatable_type).authenticatable
  end
end
