FactoryBot.define do
  factory :user_authentication do
    master_user
    authenticatable
  end
end
