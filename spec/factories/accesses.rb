FactoryBot.define do
  factory :access do
    user

    trait :super_admin do
      role { :super_admin }
    end

    trait :manager do
      role { :manager }
    end

    trait :health_care_worker do
      role { :health_care_worker }
    end
  end
end
