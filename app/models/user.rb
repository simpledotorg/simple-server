class User < ApplicationRecord
  include Mergeable

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  has_secure_password

  belongs_to :facility, foreign_key: 'registration_facility_id'
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures
  has_many :audit_logs, as: :auditable

  has_many :registered_patients, class_name: "Patient", foreign_key: "registration_user_id"

  before_create :set_otp
  before_create :set_access_token

  validates :full_name, presence: true
  validates :phone_number, presence: true, uniqueness: true
  validates :password, allow_blank: true, length: { is: 4 }, format: { with: /[0-9]/, message: 'only allows numbers' }
  validate :presence_of_password

  def presence_of_password
    unless password_digest.present? || password.present?
      errors.add(:password, 'Either password_digest or password should be present')
    end
  end

  def set_otp
    generated_otp = self.class.generate_otp
    self.otp = generated_otp[:otp]
    self.otp_valid_until = generated_otp[:otp_valid_until]
  end

  def set_access_token
    self.access_token = self.class.generate_access_token
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

  def self.generate_otp
    digits = FeatureToggle.enabled?('FIXED_OTP_ON_REQUEST_FOR_QA') ? [0] : (0..9).to_a
    otp = ''
    6.times do
      otp += digits.sample.to_s
    end
    otp_valid_until = Time.now + ENV['USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES'].to_i.minutes

    { otp: otp, otp_valid_until: otp_valid_until }
  end

  def self.generate_access_token
    SecureRandom.hex(32)
  end

  def access_token_valid?
    self.sync_approval_status_allowed?
  end

  def otp_valid?
    otp_valid_until >= Time.now
  end

  def mark_as_logged_in
    now = Time.now
    self.otp_valid_until = now
    self.logged_in_at = now
    save
  end

  def has_never_logged_in?
    logged_in_at.blank?
  end

  def reset_login
    self.logged_in_at = nil
  end

  def self.requested_sync_approval
    where(sync_approval_status: :requested)
  end

  def reset_password(password_digest)
    self.password_digest = password_digest
    self.set_access_token
    self.sync_approval_requested(I18n.t('reset_password'))
  end

  def registered_at_facility
    self.facility
  end

  def facilities_in_group
    self.facility.facility_group.facilities
  end
end
