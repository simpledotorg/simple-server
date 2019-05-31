FactoryBot.define do
  factory :user_permission do
    master_user
    resource { create :facility }
  end
end
