FactoryBot.define do
  factory :master_user do
    transient do
      password { '1234' }
      registration_facility { create(:facility) }
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
  end
end
