FactoryBot.define do
  factory :patient_phone_number do
    id { SecureRandom.uuid }
    number { Faker::PhoneNumber.phone_number }
    phone_type { 'mobile' }
    active { [true, false].sample }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    dnd_status { true }
    patient
  end
end
