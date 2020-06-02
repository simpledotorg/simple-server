class User < ApplicationRecord
  include PgSearch::Model

  AUTHENTICATION_TYPES = {
    email_authentication: 'EmailAuthentication',
    phone_number_authentication: 'PhoneNumberAuthentication'
  }

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  belongs_to :organization, optional: true

  has_many :user_authentications
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures
  has_many :registered_patients,
           inverse_of: :registration_user,
           class_name: 'Patient',
           foreign_key: :registration_user_id

  has_many :phone_number_authentications,
           through: :user_authentications,
           source: :authenticatable,
           source_type: 'PhoneNumberAuthentication'

  has_many :email_authentications,
           through: :user_authentications,
           source: :authenticatable,
           source_type: 'EmailAuthentication'

  has_many :appointments
  has_many :medical_histories
  has_many :prescription_drugs

  has_many :user_permissions, foreign_key: :user_id, dependent: :delete_all

  has_many :deleted_patients,
           inverse_of: :deleted_by_user,
           class_name: 'Patient',
           foreign_key: :deleted_by_user_id

  pg_search_scope :search_by_name, against: [:full_name], using: {tsearch: {prefix: true, any_word: true}}
  scope :search_by_email,
    ->(term) { joins(:email_authentications).merge(EmailAuthentication.search_by_email(term)) }
  scope :search_by_phone,
    ->(term) { joins(:phone_number_authentications).merge(PhoneNumberAuthentication.search_by_phone(term)) }
  scope :search_by_name_or_email, ->(term) { search_by_name(term).union(search_by_email(term)) }
  scope :search_by_name_or_phone, ->(term) { search_by_name(term).union(search_by_phone(term)) }


  validates :full_name, presence: true
  validates :role, presence: true, if: -> { email_authentication.present? }

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
      organization_id: params[:organization_id],
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
    user_permissions.where(permission_slug: permission_slug).present?
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

  def resources
    user_permissions.map(&:resource)
  end
end
