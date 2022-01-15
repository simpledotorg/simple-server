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
      @logger.info { "Starting #{self.class} with #{config.type} configuration" }
    end

    attr_reader :config
    attr_reader :logger
    attr_reader :number_of_users_per_facility
    attr_reader :organization
    delegate :stdout, to: :config

    def call
      create_dashboard_admins
      create_mobile_users
    end

    DISTRICTS_MANAGED_BY_CVHO = 2
    DISTRICTS_FOR_STS = 1
    DISTRICTS_FOR_DISTRICT_OFFICIAL = 1
    FACILITIES_FOR_MED_OFFICER = 1

    private

    def create_dashboard_admins
      unless EmailAuthentication.exists?(email: "admin@simple.org")
        FactoryBot.create(:admin, :power_user, full_name: "Admin User", email: "admin@simple.org",
                                               password: config.admin_password, organization: organization)
      end

      unless EmailAuthentication.exists?(email: "power_user@simple.org")
        FactoryBot.create(:admin, :power_user, full_name: "Power User", email: "power_user@simple.org",
                                               password: config.admin_password, organization: organization)
      end

      cvho = User.find_by_email("cvho@simple.org")
      unless cvho && cvho.accesses.where(resource_type: "FacilityGroup").count == DISTRICTS_MANAGED_BY_CVHO
        districts = *FacilityGroup.take(DISTRICTS_MANAGED_BY_CVHO)
        user = cvho || FactoryBot.create(:admin, :manager, full_name: "CVHO", email: "cvho@simple.org",
                                                           password: config.admin_password, organization: organization)
        districts.each do |district|
          user.accesses.create! resource: district
        end
      end

      sts = User.find_by_email("sts@simple.org")
      unless sts && sts.accesses.where(resource_type: "FacilityGroup").count == DISTRICTS_FOR_STS
        districts = *FacilityGroup.order("name desc").take(DISTRICTS_FOR_STS)
        user = sts || FactoryBot.create(:admin, :viewer_all, full_name: "STS", email: "sts@simple.org",
                                                             password: config.admin_password, organization: organization)
        districts.each do |district|
          user.accesses.create! resource: district
        end
      end

      district_official = User.find_by_email("district_official@simple.org")
      unless district_official && district_official.accesses.where(resource_type: "FacilityGroup").count == DISTRICTS_FOR_DISTRICT_OFFICIAL
        districts = *FacilityGroup.take(DISTRICTS_FOR_DISTRICT_OFFICIAL)
        user = district_official || FactoryBot.create(:admin, :viewer_reports_only, full_name: "District Official", email: "district_official@simple.org",
                                                                                    password: config.admin_password, organization: organization)
        districts.each do |district|
          user.accesses.create! resource: district
        end
      end

      medical_officer = User.find_by_email("medical_officer@simple.org")
      unless medical_officer && medical_officer.accesses.where(resource_type: "Facility").count == FACILITIES_FOR_MED_OFFICER
        facilities = *Facility.take(FACILITIES_FOR_MED_OFFICER)
        user = medical_officer || FactoryBot.create(:admin, :viewer_all, full_name: "Medical Officer", email: "medical_officer@simple.org",
                                                                         password: config.admin_password, organization: organization)
        facilities.each do |facility|
          user.accesses.create! resource: facility
        end
      end
    end

    def create_mobile_users
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

    # We are not using FactoryBot to keep this fast -- FactoryBot slows this down dramatically, even
    # if we use `attributes_for`
    def build_user_and_phone_number_auth_attributes(facility_ids)
      time = 30.minutes.from_now
      device_created_at = 3.months.ago
      users, auths = [], []
      facility_ids.each do |facility_id|
        number_of_users_per_facility.times do
          logger.info { "building attributes for Users and UserAuthentications" }
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
