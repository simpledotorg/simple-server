FactoryBot.define do
  factory :access do
    user

    trait :super_admin do
      mode { :super_admin }
    end

    trait :manager do
      mode { :manager }
    end

    trait :viewer do
      mode { :viewer }
    end
  end
end
