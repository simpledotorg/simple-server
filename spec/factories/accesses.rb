FactoryBot.define do
  factory :access do
    user

    trait :manager do
      mode { :manager }
    end

    trait :viewer do
      mode { :viewer }
    end
  end
end
