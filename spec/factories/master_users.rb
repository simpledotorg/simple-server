FactoryBot.define do
  factory :master_user do
    transient do
      password { '1234' }
      registration_facility { create(:facility) }
      registration_facility_id { registration_facility.id }
      phone_number { Faker::PhoneNumber.phone_number }
    end

    full_name { Faker::Name.name }

    device_created_at { Time.now }
    device_updated_at { Time.now }

    sync_approval_status { MasterUser.sync_approval_statuses[:requested] }

    trait :with_phone_number_authentication do
      after :create do |master_user, options|
        master_user.sync_approval_status = MasterUser.sync_approval_statuses[:allowed]
        master_user.sync_approval_status_reason = 'User is allowed'

        phone_number_authentication = create(
          :phone_number_authentication,
          phone_number: options.phone_number,
          password: options.password,
          facility: options.registration_facility,
        )
        master_user.user_authentications = [
          UserAuthentication.new(authenticatable: phone_number_authentication)
        ]

        master_user.save
      end
    end

    factory :master_user_with_phone_number_authentication, traits: [:with_phone_number_authentication]

    if FeatureToggle.enabled?('MASTER_USER_AUTHENTICATION')
      factory :user, traits: [:with_phone_number_authentication] do
        trait :with_sanitized_phone_number do
          phone_number { rand(1e9...1e10).to_i.to_s }
        end

        trait :sync_requested do
          sync_approval_status { MasterUser.sync_approval_statuses[:requested] }
        end
      end

      factory :user_created_on_device, traits: [:with_phone_number_authentication]
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