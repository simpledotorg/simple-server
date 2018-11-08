FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin_#{n}@example.com" }
    password "helloworld"
    role :owner

    trait(:owner) { role :owner }
    trait(:supervisor) { role :supervisor }
    trait(:analyst) { role :analyst }
  end
end
