FactoryBot.define do
  factory :questionnaire_response do
    id { SecureRandom.uuid }
    content { { } }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    association :questionnaire, strategy: :create
    association :facility
    association :user
  end
end
