FactoryBot.define do
  factory :user_permission do
    user
    resource { create :facility }
  end
end
