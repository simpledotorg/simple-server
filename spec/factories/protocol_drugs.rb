# frozen_string_literal: true

FactoryBot.define do
  factory :protocol_drug do
    id { SecureRandom.uuid }
    name { Faker::Dessert.topping }
    dosage { rand(1..10).to_s + " mg" }
    rxnorm_code { Faker::Code.npi }
    stock_tracked { false }
    drug_category { "other" }
    association :protocol
  end
end
