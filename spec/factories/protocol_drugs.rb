FactoryBot.define do
  factory :protocol_drug do
    id { SecureRandom.uuid }
    name { Faker::Dessert.topping }
    dosage { rand(1..10).to_s + " mg" }
    rxnorm_code { Faker::Code.npi }
    association :protocol, strategy: :build
  end
end
