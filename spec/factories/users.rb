FactoryBot.define do
  factory :user do
    transient do
      registration_facility { create(:facility) }
      facility { registration_facility }
      registration_facility_id { registration_facility.id }
      phone_number { Faker::PhoneNumber.phone_number }

      permissions { [] }

      email { Faker::Internet.email }
      password { Faker::Internet.password }

      organization { build(:organization) }
      facility_group { build(:facility_group, organization: organization) }
    end

    full_name { Faker::Name.name }

    device_created_at { Time.now }
    device_updated_at { Time.now }

    sync_approval_status { User.sync_approval_statuses[:requested] }



    trait :with_phone_number_authentication do
      password { '1234' }
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
    end

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

    after :create do |user, options|
      if options.permissions.present?
        user.assign_permissions(options.permissions)
      end
    end

    trait :with_email_authentication do
      role { User.roles[:owner] }

      after :create do |user, options|
        user.sync_approval_status = User.sync_approval_statuses[:denied]
        user.sync_approval_status_reason = User::DEFAULT_SYNC_APPROVAL_DENIAL_STATUS

        email_authentication = create(
          :email_authentication,
          user: user,
          email: options.email,
          password: options.password
        )

        user.user_authentications = [
          UserAuthentication.new(authenticatable: email_authentication)
        ]

        default_permissions = User::DEFAULT_PERMISSIONS_FOR_ROLE[user.role.to_sym]
        default_permissions
          .group_by { |permission_slug| Permissions::ALL_PERMISSIONS[permission_slug][:resource_type] }
          .each do |resource_type, permission_slugs|
          case resource_type
          when nil
            user.assign_permissions(permission_slugs)
          when 'Organization'
            new_permissions = permission_slugs.map { |slug| [slug, options.organization] }
            user.assign_permissions(new_permissions)
          when 'FacilityGroup'
            new_permissions = permission_slugs.map { |slug| [slug, options.facility_group] }
            user.assign_permissions(new_permissions)
          else
            puts "Skipping resource of type #{resource_type}"
          end
        end

        user.save
      end
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