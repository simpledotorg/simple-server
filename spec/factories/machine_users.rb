FactoryBot.define do
  factory :machine_user do
    name { Faker::App.name }
    organization
  end
end
