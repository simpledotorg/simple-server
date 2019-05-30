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

  def registration_facility_id
    return unless phone_number_authentication.present?
    phone_number_authentication.registration_facility_id
  end

  private

  def user_authentication_of_type(authenticatable_type)
    master_user_authentications.find_by(authenticatable_type: authenticatable_type)
  end
end
