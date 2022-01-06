# frozen_string_literal: true

FactoryBot.define do
  factory :user_authentication do
    user
    association :authenticatable, factory: :email_authentication
  end
end
