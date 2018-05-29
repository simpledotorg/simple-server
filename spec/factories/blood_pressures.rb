FactoryBot.define do
  factory :blood_pressure do
    id { SecureRandom.uuid }
    systolic { rand(80..240) }
    diastolic { rand(60..140) }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    association :patient, strategy: :build
  end
end
