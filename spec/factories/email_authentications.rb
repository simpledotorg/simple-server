FactoryBot.define do
  factory :email_authentication do
    email { Faker::Internet.email }
    password { Faker::Internet.password(min_length: 12) }
  end
end
