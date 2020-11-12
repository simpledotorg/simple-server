FactoryBot.define do
  factory :region do
    id { SecureRandom.uuid }
    name { Faker::Company.name }
    region_type { :organization }
  end
end
