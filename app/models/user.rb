class User < ApplicationRecord
  include Mergeable

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  has_secure_password

  has_many :user_facilities
  has_many :facilities, through: :user_facilities
  has_many :blood_pressures
  has_many :patients, through: :blood_pressures
  has_many :audit_logs, as: :auditable

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

  def self.generate_otp
    digits = (0..9).to_a
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
    !logged_in_at.present?
  end

  def reset_login
    self.logged_in_at = nil
  end

  def disable_access
    self.sync_approval_status = :denied
  end

  def enable_access
    self.sync_approval_status = :allowed
    set_access_token
    set_otp
    reset_login
  end
end
