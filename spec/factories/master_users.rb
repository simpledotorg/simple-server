FactoryBot.define do
  factory :master_user do
    full_name { Faker::Name.name }

    trait :with_phone_authentication do
      sync_approval_status { MasterUser.sync_approval_statuses[:allowed] }
      sync_approval_status_reason { 'User is allowed' }
    end
  end
end
