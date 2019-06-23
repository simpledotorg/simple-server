class PhoneNumberAuthentication < ApplicationRecord
  has_secure_password

  has_one :user_authentication, as: :authenticatable
  has_one :user, through: :user_authentication

  belongs_to :facility, foreign_key: 'registration_facility_id'

  delegate :facility_group, to: :facility
  delegate :organization, to: :facility_group

  validates :phone_number, presence: true, uniqueness: true, case_sensitive: false
  validates :password, allow_blank: true, length: { is: 4 }, format: { with: /[0-9]/, message: 'only allows numbers' }
  validate :presence_of_password

  alias_method :registration_facility, :facility

  def presence_of_password
    unless password_digest.present? || password.present?
      errors.add(:password, 'Either password_digest or password should be present')
    end
  end

  def has_never_logged_in?
    logged_in_at.blank?
  end

  def mark_as_logged_in
    now = Time.now
    self.otp_valid_until = now
    self.logged_in_at = now
    save
  end

  def otp_valid?
    otp_valid_until >= Time.now
  end

  def set_access_token
    self.access_token = self.class.generate_access_token
  end

  def set_otp
    generated_otp = self.class.generate_otp
    self.otp = generated_otp[:otp]
    self.otp_valid_until = generated_otp[:otp_valid_until]
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
end