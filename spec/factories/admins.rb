FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin_#{n}@example.com" }
    password "helloworld"
    role :owner

    trait(:owner) do
      role :owner
    end

    trait(:supervisor) do
      role :supervisor

    end

    trait(:analyst) do
      role :analyst
      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: FactoryBot.create(:facility_group))}
    end

    trait(:organization_owner) do
      role :organization_owner
      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: FactoryBot.create(:organization))}
    end
  end
end
