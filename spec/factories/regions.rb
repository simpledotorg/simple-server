FactoryBot.define do
  factory :region do
    id { SecureRandom.uuid }
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
    region_type { "organization" }

    trait :block do
      region_type { :block }
    end

    trait :state do
      region_type { :state }
    end
  end
end
