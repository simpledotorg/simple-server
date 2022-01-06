# frozen_string_literal: true

FactoryBot.define do
  factory :passport_authentication do
    otp { rand(100_000..999_999).to_s }
    otp_expires_at { 3.minutes.from_now }
    access_token { SecureRandom.hex(32) }

    patient_business_identifier do
      create(:patient_business_identifier, identifier_type: "simple_bp_passport")
    end
  end
end
