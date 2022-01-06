# frozen_string_literal: true

FactoryBot.define do
  factory :drug_stock do
    id { SecureRandom.uuid }
    association :facility
    region { facility.region }
    association :user
    association :protocol_drug
    for_end_of_month { Date.today.end_of_month }
    in_stock { rand(1..1000) }
    received { rand(1..1000) }
    redistributed { rand(1..1000) }
  end
end
