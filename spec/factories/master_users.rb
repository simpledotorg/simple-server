FactoryBot.define do
  factory :master_user do
    full_name { Faker::Name.name }

    device_created_at { Time.now }
    device_updated_at { Time.now }

    trait :with_phone_authentication do
      sync_approval_status { MasterUser.sync_approval_statuses[:allowed] }
      sync_approval_status_reason { 'User is allowed' }
    end
  end
end
