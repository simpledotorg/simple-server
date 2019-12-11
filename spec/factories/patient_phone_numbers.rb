FactoryBot.define do
  factory :patient_phone_number do
    id { SecureRandom.uuid }
    number { Faker::PhoneNumber.phone_number }
    phone_type { 'mobile' }
    active { [true, false].sample }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    dnd_status { true }
    patient

    trait :landline do
      phone_type { 'landline' }
    end

    trait :invalid do
      phone_type { 'invalid' }
    end

  end
end

def build_patient_phone_number_payload(phone_number = FactoryBot.build(:patient_phone_number))
  Api::Current::PatientPhoneNumberTransformer.to_response(phone_number)
end
