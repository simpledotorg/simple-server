class PhoneNumberAuthentication < ApplicationRecord
  include PgSearch::Model
  include PhoneNumberLocalization

  USER_AUTH_MAX_FAILED_ATTEMPTS = Integer(ENV["USER_AUTH_MAX_FAILED_ATTEMPTS"] || 5).freeze
  USER_AUTH_LOCKOUT_IN_MINUTES = Integer(ENV["USER_AUTH_LOCKOUT_IN_MINUTES"] || 20).freeze

  has_secure_password

  has_one :user_authentication, as: :authenticatable
  has_one :user, through: :user_authentication

  belongs_to :facility, foreign_key: "registration_facility_id"

  pg_search_scope :search_by_phone, against: [:phone_number], using: {tsearch: {any_word: true}}

  delegate :facility_group, to: :facility
  delegate :organization, to: :facility_group

  validates :phone_number, presence: true, uniqueness: true, case_sensitive: false
  validates :password, allow_blank: true, length: {is: 4}, format: {with: /[0-9]/, message: "only allows numbers"}
  validates :failed_attempts, numericality: {only_integer: true, less_than_or_equal_to: 5}
  validate :presence_of_password

  alias_method :registration_facility, :facility

  def presence_of_password
    unless password_digest.present? || password.present?
      errors.add(:password, "Either password_digest or password should be present")
    end
  end

  def has_never_logged_in?
    logged_in_at.blank?
  end

  def mark_as_logged_in
    now = Time.current
    self.otp_expires_at = now
    self.logged_in_at = now
    save
  end

  def unlock
    update!(locked_at: nil, failed_attempts: 0)
  end

  def in_lockout_period?
    locked_at && locked_at >= lockout_time.ago
  end

  def lockout_time
    USER_AUTH_LOCKOUT_IN_MINUTES.minutes
  end

  def track_failed_attempt
    increment!(:failed_attempts)
    if failed_attempts >= USER_AUTH_MAX_FAILED_ATTEMPTS
      update!(locked_at: Time.current)
    end
  end

  def minutes_left_on_lockout
    minutes_left = (lockout_time - (Time.current - locked_at)) / 1.minute
    minutes_left.round
  end

  def otp_valid?
    otp_expires_at >= Time.current
  end

  def set_access_token
    self.access_token = self.class.generate_access_token
  end

  def set_otp
    generated_otp = self.class.generate_otp
    self.otp = generated_otp[:otp]
    self.otp_expires_at = generated_otp[:otp_expires_at]
  end

  def invalidate_otp
    self.otp_expires_at = Time.at(0)
  end

  def self.generate_otp
    digits = Flipper.enabled?(:fixed_otp) ? [0] : (0..9).to_a
    otp = ""
    6.times do
      otp += digits.sample.to_s
    end
    otp_expires_at = Time.current + ENV["USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES"].to_i.minutes

    {otp: otp, otp_expires_at: otp_expires_at}
  end

  def self.generate_access_token
    SecureRandom.hex(32)
  end
end
