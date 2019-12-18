FactoryBot.define do
  factory :user_authentication do
    user
    association :authenticatable, factory: :email_authentication
  end
end
