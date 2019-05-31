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

  enum user_type: {
    nurse: 'nurse',
    admin: 'admin',
    analyst: 'analyst',
    root: 'root'
  }

  has_many :user_authentications
  has_many :email_authentications, through: :user_authentications, source: :authenticatable, source_type: 'EmailAuthentication'
  has_many :user_permissions, foreign_key: :user_id

  validates :full_name, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  DEFAULT_SYNC_APPROVAL_DENIAL_STATUS = 'User does not need to sync'.freeze

  def phone_number_authentication
    user_authentication_of_type(AUTHENTICATION_TYPES[:phone_number_authentication])
  end

  def registration_facility_id
    return unless phone_number_authentication.present?
    phone_number_authentication.registration_facility_id
  end

  def authorized?(permission_slug, resource: nil)
    user_permissions.find_by(permission_slug: permission_slug, resource: resource).present?
  end

  def has_permission?(permission_slug)
    user_permissions.find_by(permission_slug: permission_slug).present?
  end

  private

  def user_authentication_of_type(authenticatable_type)
    master_user_authentications.find_by(authenticatable_type: authenticatable_type)
  end
end
