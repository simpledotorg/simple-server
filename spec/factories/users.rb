FactoryBot.define do
  factory :user do
    transient do
      password { '1234' }
      registration_facility { create(:facility) }
      facility { registration_facility }
      registration_facility_id { registration_facility.id }
      phone_number { Faker::PhoneNumber.phone_number }
    end

    full_name { Faker::Name.name }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    sync_approval_status { User.sync_approval_statuses[:requested] }

    after :create do |user, options|
      user.sync_approval_status = User.sync_approval_statuses[:allowed]
      user.sync_approval_status_reason = 'User is allowed'

      phone_number_authentication = create(
        :phone_number_authentication,
        phone_number: options.phone_number,
        password: options.password,
        facility: options.registration_facility || options.facility,
      )
      user.user_authentications = [
        UserAuthentication.new(authenticatable: phone_number_authentication)
      ]

      user.save
    end

    trait :with_phone_number_authentication
    trait :with_sanitized_phone_number do
      phone_number { rand(1e9...1e10).to_i.to_s }
    end

    trait :sync_requested do
      sync_approval_status { User.sync_approval_statuses[:requested] }
    end

    trait :sync_allowed do
      sync_approval_status { User.sync_approval_statuses[:allowed] }
    end

    trait :sync_denied do
      sync_approval_status { User.sync_approval_statuses[:denied] }
    end

    trait :created_on_device
    factory :user_created_on_device, traits: [:with_phone_number_authentication]
  end

  factory :admin, class: User do
    transient do
      email { Faker::Internet.email(full_name) }
      password { Faker::Internet.password(6) }
    end

    full_name { Faker::Name.name }
    device_created_at { Time.now }
    device_updated_at { Time.now }
    sync_approval_status { User.sync_approval_statuses[:denied] }
    email_authentications { create_list(:email_authentication, 1, email: email, password: password) }

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

    trait(:counsellor) do
      role :counsellor
      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: FactoryBot.create(:facility_group))}
    end

    trait(:organization_owner) do
      role :organization_owner
      admin_access_controls { FactoryBot.create_list(:admin_access_control, 1, access_controllable: FactoryBot.create(:organization))}
    end
  end
end

def register_user_request_params(arguments = {})
  { id: SecureRandom.uuid,
    full_name: Faker::Name.name,
    phone_number: Faker::PhoneNumber.phone_number,
    password_digest: BCrypt::Password.create("1234"),
    registration_facility_id: SecureRandom.uuid,
    created_at: Time.now.iso8601,
    updated_at: Time.now.iso8601
  }.merge(arguments)
end