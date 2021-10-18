class User < ApplicationRecord
  include Memery
  include Flipperable
  include PgSearch::Model

  AUTHENTICATION_TYPES = {
    email_authentication: "EmailAuthentication",
    phone_number_authentication: "PhoneNumberAuthentication"
  }

  APP_USER_CAPABILITIES = [:can_teleconsult].freeze
  CAPABILITY_VALUES = {
    true => "yes",
    false => "no"
  }.freeze

  enum sync_approval_status: {
    requested: "requested",
    allowed: "allowed",
    denied: "denied"
  }, _prefix: true
  enum access_level: UserAccess::LEVELS.map { |level, info| [level, info[:id].to_s] }.to_h, _suffix: :access

  def can_teleconsult?
    teleconsultation_facilities.any?
  end

  def app_capabilities
    {can_teleconsult: CAPABILITY_VALUES[can_teleconsult?]}
  end

  belongs_to :organization, optional: true
  has_many :user_authentications
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures
  has_many :registered_patients,
    inverse_of: :registration_user,
    class_name: "Patient",
    foreign_key: :registration_user_id
  has_many :phone_number_authentications,
    through: :user_authentications,
    source: :authenticatable,
    source_type: "PhoneNumberAuthentication"
  has_many :email_authentications,
    through: :user_authentications,
    source: :authenticatable,
    source_type: "EmailAuthentication"
  has_many :appointments
  has_many :medical_histories
  has_many :prescription_drugs
  has_many :requested_teleconsultations,
    class_name: "Teleconsultation",
    foreign_key: :requester_id
  has_many :recorded_teleconsultations,
    class_name: "Teleconsultation",
    foreign_key: :medical_officer_id
  has_many :deleted_patients,
    inverse_of: :deleted_by_user,
    class_name: "Patient",
    foreign_key: :deleted_by_user_id
  has_and_belongs_to_many :teleconsultation_facilities,
    class_name: "Facility",
    join_table: "facilities_teleconsultation_medical_officers"
  has_many :accesses, dependent: :destroy
  has_many :drug_stocks

  pg_search_scope :search_by_name, against: [:full_name], using: {tsearch: {prefix: true, any_word: true}}
  pg_search_scope :search_by_teleconsultation_phone_number,
    against: [:teleconsultation_phone_number],
    using: {tsearch: {any_word: true}}

  scope :search_by_email,
    ->(term) { joins(:email_authentications).merge(EmailAuthentication.search_by_email(term)) }
  scope :search_by_phone,
    ->(term) { joins(:phone_number_authentications).merge(PhoneNumberAuthentication.search_by_phone(term)) }
  scope :search_by_name_or_email, ->(term) { search_by_name(term).union(search_by_email(term)) }
  scope :search_by_name_or_phone, ->(term) { search_by_name(term).union(search_by_phone(term)) }
  scope :teleconsult_search, ->(term) do
    search_by_teleconsultation_phone_number(term).union(search_by_name_or_phone(term))
  end
  scope :non_admins, -> { joins(:phone_number_authentications).where.not(phone_number_authentications: {id: nil}) }
  scope :admins, -> { joins(:email_authentications).where.not(email_authentications: {id: nil}) }

  def self.find_by_email(email)
    joins(:email_authentications).find_by(email_authentications: {email: email})
  end

  validates :full_name, presence: true
  validates :role, presence: true, if: -> { email_authentication.present? }
  validates :teleconsultation_phone_number, allow_blank: true, format: {with: /\A[0-9]+\z/, message: "only allows numbers"}
  validates_presence_of :teleconsultation_isd_code, if: -> { teleconsultation_phone_number.present? }
  validates :access_level, presence: true, if: -> { email_authentication.present? }
  validates :receive_approval_notifications, inclusion: {in: [true, false]}
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  delegate :registration_facility,
    :access_token,
    :logged_in_at,
    :has_never_logged_in?,
    :mark_as_logged_in,
    :phone_number,
    :localized_phone_number,
    :otp,
    :otp_valid?,
    :facility_group,
    :password_digest, to: :phone_number_authentication, allow_nil: true
  delegate :email,
    :password,
    :authenticatable_salt,
    :invited_to_sign_up?, to: :email_authentication, allow_nil: true
  delegate :accessible_organizations,
    :accessible_facilities,
    :accessible_facility_groups,
    :accessible_district_regions,
    :accessible_block_regions,
    :accessible_facility_regions,
    :accessible_users,
    :accessible_admins,
    :accessible_protocols,
    :accessible_protocol_drugs,
    :access_across_organizations?,
    :access_across_facility_groups?,
    :can_access?,
    :manage_organization?,
    :grant_access,
    :permitted_access_levels, to: :user_access, allow_nil: false

  after_destroy :destroy_email_authentications
  after_discard :destroy_email_authentications

  def phone_number_authentication
    phone_number_authentications.first
  end

  def email_authentication
    email_authentications.first
  end

  def user_access
    UserAccess.new(self)
  end

  def region_access(memoized: false)
    @region_access ||= RegionAccess.new(self, memoized: memoized)
  end

  def registration_facility_id
    registration_facility.id
  end

  alias_method :facility, :registration_facility

  def full_teleconsultation_phone_number
    number = teleconsultation_phone_number.presence || phone_number
    isd_code = teleconsultation_isd_code || Rails.application.config.country["sms_country_code"]
    Phonelib.parse(isd_code + number).full_e164
  end

  def authorized_facility?(facility_id)
    registration_facility && registration_facility.facility_group.facilities.where(id: facility_id).present?
  end

  def access_token_valid?
    sync_approval_status_allowed?
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
    user.sync_approval_requested(I18n.t("registration"))

    user.phone_number_authentications = [phone_number_authentication]
    user
  end

  def update_with_phone_number_authentication(params)
    user_params = params.slice(
      :full_name,
      :teleconsultation_phone_number,
      :teleconsultation_isd_code,
      :sync_approval_status,
      :sync_approval_status_reason
    )
    phone_number_authentication_params = params.slice(
      :phone_number,
      :password,
      :password_digest,
      :registration_facility_id
    )

    transaction do
      update(user_params) && phone_number_authentication.update!(phone_number_authentication_params)
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

  def reset_phone_number_authentication_password!(password_digest)
    transaction do
      authentication = phone_number_authentication
      authentication.password_digest = password_digest
      authentication.set_access_token
      sync_approval_requested(I18n.t("reset_password")) unless feature_enabled?(:auto_approve_users)
      authentication.save!
      save!
    end
  end

  def self.requested_sync_approval
    where(sync_approval_status: :requested)
  end

  def destroy_email_authentications
    destroyable_email_auths = email_authentications.load

    user_authentications.each(&:destroy)
    destroyable_email_auths.each(&:destroy)

    true
  end

  def regions_access_cache_key
    power_user? ? "users/power_user_region_access" : cache_key
  end

  def power_user?
    power_user_access? && email_authentication.present?
  end

  def district_level_sync?
    can_teleconsult?
  end

  memoize def drug_stocks_enabled?
    facility_group_ids = accessible_facilities(:view_reports).select(:facility_group_id).distinct

    Region.where(source_id: facility_group_ids).any? { |district| district.feature_enabled?(:drug_stocks) }
  end
end
