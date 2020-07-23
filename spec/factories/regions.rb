FactoryBot.define do
  factory :region do
    id { SecureRandom.uuid }
    name { Faker::Address.district }
    level { :state }
    description { Faker::Company.catch_phrase }
  end
end
