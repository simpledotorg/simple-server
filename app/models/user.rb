class User < ApplicationRecord
  self.table_name = 'master_users'

  AUTHENTICATION_TYPES = {
    email_authentication: 'EmailAuthentication',
    phone_number_authentication: 'PhoneNumberAuthentication'
  }

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  enum role: {
    owner: 'owner',
    supervisor: 'supervisor',
    analyst: 'analyst',
    organization_owner: 'organization_owner',
    counsellor: 'counsellor'
  }

  belongs_to :organization

  has_many :user_authentications
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures

  has_many :phone_number_authentications,
           through: :user_authentications,
           source: :authenticatable,
           source_type: 'PhoneNumberAuthentication'

  has_many :email_authentications,
           through: :user_authentications,
           source: :authenticatable,
           source_type: 'EmailAuthentication'

  has_many :user_permissions, foreign_key: :user_id

  has_many :audit_logs, as: :auditable

  validates :full_name, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  delegate :registration_facility,
           :access_token,
           :logged_in_at,
           :has_never_logged_in?,
           :mark_as_logged_in,
           :phone_number,
           :otp,
           :otp_valid?,
           :facility_group,
           :password_digest, to: :phone_number_authentication, allow_nil: true

  delegate :email,
           :password,
           :authenticatable_salt,
           :invited_to_sign_up?, to: :email_authentication, allow_nil: true

  def self.invite!(options = {})
    transaction do
      now = Time.now
      User.create(
        options
          .slice(:full_name, :role)
          .merge(device_created_at: now,
                 device_updated_at: now,
                 sync_approval_status: sync_approval_statuses[:denied]))

      EmailAuthentication.invite!(nil, options.slice(:email))
    end
  end

  def phone_number_authentication
    phone_number_authentications.first
  end

  def email_authentication
    email_authentications.first
  end

  def registration_facility_id
    registration_facility.id
  end

  alias_method :facility, :registration_facility

  def access_token_valid?
    self.sync_approval_status_allowed?
  end

  def self.build_with_phone_number_authentication(params)
    phone_number_authentication = PhoneNumberAuthentication.new(
      phone_number: params[:phone_number],
      password_digest: params[:password_digest],
      registration_facility_id: params[:registration_facility_id]
    )
    phone_number_authentication.set_otp
    phone_number_authentication.set_access_token

    user = new(
      id: params[:id],
      full_name: params[:full_name],
      device_created_at: params[:device_created_at],
      device_updated_at: params[:device_updated_at]
    )
    user.sync_approval_requested(I18n.t('registration'))

    user.phone_number_authentications = [phone_number_authentication]
    user
  end

  def update_with_phone_number_authentication(params)
    user_params = params.slice(:full_name, :sync_approval_status, :sync_approval_status_reason)
    phone_number_authentication_params = params.slice(
      :phone_number,
      :password,
      :password_digest,
      :registration_facility_id
    )

    transaction do
      update!(user_params) && phone_number_authentication.update!(phone_number_authentication_params)
    end
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

  def authorized?(permission_slug, resource: nil)
    user_permissions.find_by(permission_slug: permission_slug, resource: resource).present?
  end

  def has_permission?(permission_slug)
    user_permissions.find_by(permission_slug: permission_slug).present?
  end

  def reset_phone_number_authentication_password!(password_digest)
    transaction do
      authentication = phone_number_authentication
      authentication.password_digest = password_digest
      authentication.set_access_token
      self.sync_approval_requested(I18n.t('reset_password'))
      authentication.save!
      self.save!
    end
  end

  def self.requested_sync_approval
    where(sync_approval_status: :requested)
  end

  def has_role?(*roles)
    roles.map(&:to_sym).include?(self.role.to_sym)
  end
end
