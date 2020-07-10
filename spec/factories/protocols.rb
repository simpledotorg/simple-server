FactoryBot.define do
  factory :protocol do
    id { SecureRandom.uuid }
    name { Faker::Address.state + " Protocol" }
    follow_up_days { rand(1..60) }
  end
end
