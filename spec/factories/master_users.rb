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

      transient do
        organization { build(:organization) }
        facility_group { build(:facility_group, organization: organization) }
      end

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

        default_permissions = MasterUser::DEFAULT_PERMISSIONS_FOR_ROLE[master_user.role.to_sym]
        default_permissions
          .group_by { |permission_slug| Permissions::ALL_PERMISSIONS[permission_slug][:resource_type] }
          .each do |resource_type, permission_slugs|
          case resource_type
          when nil
            master_user.assign_permissions(permission_slugs)
          when 'Organization'
            new_permissions = permission_slugs.map { |slug| [slug, options.organization] }
            master_user.assign_permissions(new_permissions)
          when 'FacilityGroup'
            new_permissions = permission_slugs.map { |slug| [slug, options.facility_group] }
            master_user.assign_permissions(new_permissions)
          else
            puts "Skipping resource of type #{resource_type}"
          end
        end

        master_user.save
      end
    end
  end
end
