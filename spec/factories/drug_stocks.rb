FactoryBot.define do
  factory :drug_stock do
    id { SecureRandom.uuid }
    association :facility, strategy: :create
    association :user, strategy: :create
    association :protocol_drug, strategy: :create
    recorded_at { Time.current }
    in_stock { 500 }
    received { 500 }
  end
end
