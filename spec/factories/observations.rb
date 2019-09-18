FactoryBot.define do
  factory :observation do
    encounter_id { SecureRandom.uuid }
    observable_id { SecureRandom.uuid }
    observable_type 'BloodPressure'
    user_id { SecureRandom.uuid }
  end
end
