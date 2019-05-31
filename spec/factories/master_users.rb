FactoryBot.define do
  factory :master_user do
    full_name { Faker::Name.name }

    device_created_at { Time.now }
    device_updated_at { Time.now }

    sync_approval_status { MasterUser.sync_approval_statuses[:requested] }
    user_type { 'nurse' }
    organization

    transient do
      email { Faker::Internet.email }
      password { Faker::Internet.password }
    end

    trait :with_phone_authentication do
      sync_approval_status { MasterUser.sync_approval_statuses[:allowed] }
      sync_approval_status_reason { 'User is allowed' }
    end

    trait :with_email_authentication do
      after :create do |master_user, options|
        master_user.sync_approval_status = MasterUser.sync_approval_statuses[:denied]
        master_user.sync_approval_status_reason = MasterUser::DEFAULT_SYNC_APPROVAL_DENIAL_STATUS

        email_authentication = create(
          :email_authentication,
          email: options.email,
          password: options.password
        )

        master_user.user_authentications = [
          UserAuthentication.new(authenticatable: email_authentication)
        ]

        master_user.save
      end
    end
  end
end
