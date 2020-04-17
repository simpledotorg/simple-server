FactoryBot.define do
  factory :passport_authentication do
    otp { rand(100_000..999_999).to_s }
    otp_valid_until { 3.minutes.from_now }
    access_token { SecureRandom.hex(32) }

    patient
    patient_business_identifier do
      create(:patient_business_identifier, patient: patient, identifier_type: 'simple_bp_passport')
    end
  end
end
