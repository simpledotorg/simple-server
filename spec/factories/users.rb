FactoryBot.define do
  factory :user do
    transient do
      password { "1234" }
      registration_facility { create(:facility) }
      phone_number { Faker::PhoneNumber.phone_number }
    end

    full_name { Faker::Name.name }
    organization
    device_created_at { Time.current }
    device_updated_at { Time.current }

    sync_allowed

    after :create do |user, options|
      phone_number_authentication = create(
        :phone_number_authentication,
        phone_number: options.phone_number,
        password: options.password,
        facility: options.registration_facility
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
      sync_approval_status_reason { "New registration" }
    end

    trait :sync_allowed do
      sync_approval_status { User.sync_approval_statuses[:allowed] }
      sync_approval_status_reason { "User is allowed" }
    end

    trait :sync_denied do
      sync_approval_status { User.sync_approval_statuses[:denied] }
      sync_approval_status_reason { "No particular reason" }
    end

    trait :created_on_device
    factory :user_created_on_device, traits: [:with_phone_number_authentication]
  end

  sequence(:strong_password) do |n|
    [Faker::Name.first_name, Faker::Name.last_name, Faker::Internet.domain_word, n].join("-")
  end

  factory :admin, class: User do
    transient do
      email { Faker::Internet.email(name: full_name) }
      password { generate(:strong_password) }
      facility_group { build(:facility_group) }
    end

    full_name { Faker::Name.name }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    sync_approval_status { User.sync_approval_statuses[:denied] }
    email_authentications { build_list(:email_authentication, 1, email: email, password: password) }
    user_permissions { [] }
    organization

    role { :owner }

    trait(:owner) do
      role { :owner }

      after :create do |user, _options|
        access_level = Permissions::ACCESS_LEVELS.find { |access_level| access_level[:name] == user.role.to_sym }
        access_level[:default_permissions].each do |slug|
          user.user_permissions.create(permission_slug: slug)
        end
      end
    end

    trait(:supervisor) do
      role { :supervisor }
      after :create do |user, options|
        access_level = Permissions::ACCESS_LEVELS.find { |access_level| access_level[:name] == user.role.to_sym }
        access_level[:default_permissions].each do |slug|
          user.user_permissions.create(permission_slug: slug, resource: options.facility_group)
        end
      end
    end

    trait(:analyst) do
      role { :analyst }
      after :create do |user, options|
        access_level = Permissions::ACCESS_LEVELS.find { |access_level| access_level[:name] == user.role.to_sym }
        access_level[:default_permissions].each do |slug|
          user.user_permissions.create(permission_slug: slug, resource: options.facility_group)
        end
      end
    end

    trait(:counsellor) do
      role { :counsellor }
      after :create do |user, options|
        access_level = Permissions::ACCESS_LEVELS.find { |access_level| access_level[:name] == user.role.to_sym }
        access_level[:default_permissions].each do |slug|
          user.user_permissions.create(permission_slug: slug, resource: options.facility_group)
        end
      end
    end

    trait(:organization_owner) do
      role { :organization_owner }
      after :create do |user, options|
        access_level = Permissions::ACCESS_LEVELS.find { |access_level| access_level[:name] == user.role.to_sym }
        access_level[:default_permissions].each do |slug|
          user.user_permissions.create(permission_slug: slug, resource: options.organization)
        end
      end
    end
  end
end

def register_user_request_params(arguments = {})
  {id: SecureRandom.uuid,
   full_name: Faker::Name.name,
   phone_number: Faker::PhoneNumber.phone_number,
   password_digest: BCrypt::Password.create("1234"),
   registration_facility_id: SecureRandom.uuid,
   created_at: Time.current.iso8601,
   updated_at: Time.current.iso8601}.merge(arguments)
end
