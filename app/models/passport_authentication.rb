# frozen_string_literal: true

class PassportAuthentication < ActiveRecord::Base
  after_initialize :generate_access_token, if: :new_record?
  after_initialize :generate_otp, if: :new_record?

  belongs_to :patient_business_identifier
  delegate :patient, to: :patient_business_identifier

  validates :access_token, presence: true
  validates :otp, presence: true
  validates :otp_expires_at, presence: true
  validates :patient_business_identifier, presence: true

  def otp_valid?
    otp_expires_at >= Time.current
  end

  def generate_access_token
    self.access_token ||= SecureRandom.hex(32)
  end

  def reset_access_token
    self.access_token = SecureRandom.hex(32)
  end

  def generate_otp
    new_otp = build_otp

    self.otp ||= new_otp[:otp]
    self.otp_expires_at ||= new_otp[:otp_expires_at]

    {otp: otp, otp_expires_at: otp_expires_at}
  end

  def reset_otp
    new_otp = build_otp

    self.otp = new_otp[:otp]
    self.otp_expires_at = new_otp[:otp_expires_at]

    {otp: otp, otp_expires_at: otp_expires_at}
  end

  def expire_otp
    self.otp_expires_at = Time.at(0)
  end

  def validate_otp(otp)
    if self.otp == otp && otp_valid?
      reset_access_token
      expire_otp
      save!
      true
    else
      false
    end
  end

  private

  def build_otp
    new_otp = if Flipper.enabled?(:fixed_otp)
      "000000"
    else
      SecureRandom.random_number.to_s[2..7]
    end

    new_otp_expires_at = Time.current + ENV["USER_OTP_VALID_UNTIL_DELTA_IN_MINUTES"].to_i.minutes

    {otp: new_otp, otp_expires_at: new_otp_expires_at}
  end
end
