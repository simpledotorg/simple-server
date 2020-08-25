FactoryBot.define do
  factory :access do
    user { build(:admin) }
  end
end
