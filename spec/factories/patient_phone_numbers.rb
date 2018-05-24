FactoryBot.define do
  factory :patient_phone_number do
    association :patient, strategy: :build
    association :phone_number, strategy: :build
    updated_on_server_at  { Time.now }
  end
end
