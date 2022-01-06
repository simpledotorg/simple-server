# frozen_string_literal: true

FactoryBot.define do
  factory :email_authentication do
    email { Faker::Internet.email }
    password { generate(:strong_password) }
  end
end
