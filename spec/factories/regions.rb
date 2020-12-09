FactoryBot.define do
  factory :region do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    region_type { "organization" }

    trait :block do
      region_type { :block }
    end

    trait :state do
      region_type { :state }
    end
  end
end
