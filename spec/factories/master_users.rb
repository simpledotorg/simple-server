FactoryBot.define do
  factory :master_user do
    full_name { Faker::Name.name }

    device_created_at { Time.now }
    device_updated_at { Time.now }

    sync_approval_status { MasterUser.sync_approval_statuses[:requested] }
    role { MasterUser.roles[:nurse] }

    transient do
      email { Faker::Internet.email }
      password { Faker::Internet.password }

      permissions { [] }
    end

    trait :with_phone_authentication do
      sync_approval_status { MasterUser.sync_approval_statuses[:allowed] }
      sync_approval_status_reason { 'User is allowed' }
    end

    after :create do |master_user, options|
      if options.permissions.present?
        master_user.assign_permissions(options.permissions)
      end
    end

    trait :with_email_authentication do
      role { MasterUser.roles[:owner] }
      permissions { [] }

      after :create do |master_user, options|
        master_user.sync_approval_status = MasterUser.sync_approval_statuses[:denied]
        master_user.sync_approval_status_reason = MasterUser::DEFAULT_SYNC_APPROVAL_DENIAL_STATUS

        email_authentication = create(
          :email_authentication,
          master_user: master_user,
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
