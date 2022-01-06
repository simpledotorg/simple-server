# frozen_string_literal: true

FactoryBot.define do
  factory :observation do
    id { Faker::Number.unique.number }
    encounter_id { SecureRandom.uuid }
    observable_id { SecureRandom.uuid }
    observable_type { "BloodPressure" }
    user_id { SecureRandom.uuid }
    created_at { Time.now }
    updated_at { Time.now }
  end
end
