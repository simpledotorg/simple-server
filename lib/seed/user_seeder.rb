module Seed
  class UserSeeder
    include ActiveSupport::Benchmarkable
    include ConsoleLogger

    def self.call(*args)
      new(*args).call
    end

    def initialize(config:)
      @counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      @number_of_users_per_facility = config.max_number_of_users_per_facility
      @organization = Seed.seed_org
      announce "Starting #{self.class} with #{config.type} configuration"
    end

    attr_reader :config
    attr_reader :logger
    attr_reader :number_of_users_per_facility
    attr_reader :organization
    delegate :stdout, to: :config

    def call
      power_user = FactoryBot.create(:admin, :power_user, full_name: "Power User", email: "power_user@simple.org", password: config.admin_password)

      fg_1, fg_2 = *FacilityGroup.take(2)
      user = FactoryBot.create(:admin, :manager, full_name: "CVHO", email: "cvho@simple.org")
      user.accesses.create! resource_id: fg_1.id, resource_type: "FacilityGroup"
      user.accesses.create! resource_id: fg_2.id, resource_type: "FacilityGroup"

      facility_ids = Facility.pluck(:id)
      users, auths = benchmark("build phone number auths and users for #{facility_ids.size} facilities") do
        build_user_and_phone_number_auth_attributes(facility_ids)
      end

      user_results, phone_results = nil, nil
      benchmark("importing users and phone number auths") do
        user_results = User.import!(users)
        phone_results = PhoneNumberAuthentication.import!(auths)
      end
      user_ids_phone_ids = user_results.ids.zip(phone_results.ids)
      auths = user_ids_phone_ids.map { |(user_id, phone_id)|
        {user_id: user_id, authenticatable_type: PhoneNumberAuthentication.name, authenticatable_id: phone_id}
      }
      benchmark("importing user auths") do
        UserAuthentication.import(auths)
      end
    end

    private

    # We are not using FactoryBot to keep this fast -- FactoryBot slows this down dramatically, even
    # if we use `attributes_for`
    def build_user_and_phone_number_auth_attributes(facility_ids)
      time = 30.minutes.from_now
      device_created_at = 3.months.ago
      users, auths = [], []
      facility_ids.each do |facility_id|
        number_of_users_per_facility.times do
          auths << {
            phone_number: Faker::PhoneNumber.phone_number,
            otp: rand(100_000..999_999).to_s,
            otp_expires_at: time,
            access_token: SecureRandom.hex(32),
            registration_facility_id: facility_id,
            password_digest: Faker::Crypto.sha256
          }
          users << {
            full_name: Faker::Name.name,
            organization_id: organization.id,
            device_created_at: device_created_at,
            device_updated_at: device_created_at,
            sync_approval_status: User.sync_approval_statuses[:allowed],
            sync_approval_status_reason: "User is allowed",
            role: config.seed_generated_active_user_role
          }
        end
      end
      [users, auths]
    end
  end
end
