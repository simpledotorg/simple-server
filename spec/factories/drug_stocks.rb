FactoryBot.define do
  factory :drug_stock do
    id { SecureRandom.uuid }
    association :facility, strategy: :create
    association :user, strategy: :create
    association :protocol_drug, strategy: :create
    for_end_of_month { Date.today.end_of_month }
    in_stock { 500 }
    received { 100 }
  end
end
