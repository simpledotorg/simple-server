# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    transient do
      password { "1234" }
      registration_facility { create(:facility) }
      phone_number { Faker::PhoneNumber.phone_number }
    end

    full_name { Faker::Name.name }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    teleconsultation_phone_number { rand > 0.50 ? Faker::PhoneNumber.phone_number : nil }
    teleconsultation_isd_code { "+91" }

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

      user.save!
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
    Faker::Lorem.characters(number: 9, min_alpha: 9).capitalize + n.to_s
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
    role { "power user" }
    receive_approval_notifications { true }
    access_level { :power_user }

    trait :call_center do
      access_level { :call_center }
    end

    trait :viewer_reports_only do
      access_level { :viewer_reports_only }
    end

    trait :viewer_all do
      access_level { :viewer_all }
    end

    trait :manager do
      access_level { :manager }
    end

    trait :power_user do
      access_level { :power_user }
    end

    trait :with_access do
      transient do
        resource { nil }
      end

      accesses { [build(:access, user_id: id, resource: resource)] }
    end
  end
end

def register_user_request_params(arguments = {})
  {
    id: SecureRandom.uuid,
    full_name: Faker::Name.name,
    phone_number: Faker::PhoneNumber.phone_number,
    teleconsultation_phone_number: Faker::PhoneNumber.phone_number,
    teleconsultation_isd_code: "+91",
    password_digest: BCrypt::Password.create("1234"),
    registration_facility_id: SecureRandom.uuid,
    created_at: Time.current.iso8601,
    updated_at: Time.current.iso8601
  }.merge(arguments)
end
