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

  def phone_number
    delegate_to_phone_number_authentication(:phone_number)
  end

  def otp
    delegate_to_phone_number_authentication(:otp)
  end

  def otp_valid?
    delegate_to_phone_number_authentication(:otp_valid?)
  end

  def facility_group
    delegate_to_phone_number_authentication(:facility_group)
  end

  def organization
    delegate_to_phone_number_authentication(:organization)
  end

  def self.build_with_phone_number_authentication(params)
    phone_number_authentication = PhoneNumberAuthentication.new(
      phone_number: params[:phone_number],
      password_digest: params[:password_digest],
      registration_facility_id: params[:registration_facility_id]
    )
    phone_number_authentication.set_otp
    phone_number_authentication.set_access_token

    master_user = new(
      id: params[:id],
      full_name: params[:full_name],
      device_created_at: params[:device_created_at],
      device_updated_at: params[:device_updated_at]
    )
    master_user.sync_approval_requested(I18n.t('registration'))

    master_user.user_authentications = [
      UserAuthentication.new(
        master_user: master_user,
        authenticatable: phone_number_authentication
      )
    ]

    { master_user: master_user, phone_number_authentication: phone_number_authentication}
  end

  def sync_approval_denied(reason = "")
    self.sync_approval_status = :denied
    self.sync_approval_status_reason = reason
  end

  def sync_approval_allowed(reason = "")
    self.sync_approval_status = :allowed
    self.sync_approval_status_reason = reason
  end

  def sync_approval_requested(reason)
    self.sync_approval_status = :requested
    self.sync_approval_status_reason = reason
  end

  def reset_phone_number_authentication_password!(password_digest)
    transaction do
      authentication = phone_number_authentication
      authentication.password_digest = password_digest
      authentication.set_access_token
      self.sync_approval_requested(I18n.t('reset_password'))
      authentication.save
      self.save
    end
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
