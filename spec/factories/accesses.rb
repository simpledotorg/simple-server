FactoryBot.define do
  factory :access do
    user

    trait :super_admin do
      role { :super_admin }
    end

    trait :manager do
      role { :manager }
    end

    trait :viewer do
      role { :viewer }
    end
  end
end
