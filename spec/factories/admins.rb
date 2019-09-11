FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin_#{Faker::Name.first_name}_#{Faker::Name.last_name}_#{n}_@example.com" }
    password "helloworld"
    role :owner

    transient do
      organization { create(:organization) }
      facility_group { create(:facility_group) }
    end

    trait(:owner) do
      role :owner
    end

    trait(:supervisor) do
      role :supervisor
    end

    trait(:analyst) do
      role :analyst
      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: facility_group) }
    end

    trait(:counsellor) do
      role :counsellor
      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: facility_group) }
    end

    trait(:organization_owner) do
      role :organization_owner

      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: organization) }
    end
  end
end
