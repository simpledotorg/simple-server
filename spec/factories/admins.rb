FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin_#{n}@example.com" }
    password "helloworld"
    role :admin

    trait(:supervisor) { role: :supervisor }
  end
end
