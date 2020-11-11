require_dependency "seed/config"

module Seed
  class FacilitySeeder
    ADMIN_USER_NAME = "Admin User"
    ADMIN_USER_EMAIL = "admin@simple.org"

    def self.call(*args)
      new(*args).call
    end

    def initialize(config:)
      @counts = {}
      @config = config
      @logger = Rails.logger.child(class: self.class.name)
      puts "Starting #{self.class} with #{config.type} configuration"
    end

    attr_reader :config

    delegate :scale_factor, to: :config

    def number_of_facility_groups
      config.number_of_facility_groups
    end

    def number_of_facilities_per_facility_group
      rand(1..config.max_number_of_facilities_per_facility_group)
    end

    def number_of_users
      rand(1..config.max_number_of_users_per_facility)
    end

    def call
      Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
      org_name = "IHCI"
      organization = Organization.find_by(name: org_name) || FactoryBot.create(:organization, name: org_name)
      return if number_of_facility_groups <= FacilityGroup.count
      number_of_facility_groups.times do
        facility_group_params = {organization: organization}
        facility_group = FactoryBot.create(:facility_group, facility_group_params)

        number_of_facilities_per_facility_group.times do
          type = facility_size_map.keys.sample
          size = facility_size_map[type]

          facility_attrs = {
            district: facility_group.name,
            facility_group_id: facility_group.id,
            facility_size: size,
            facility_type: type
          }
          facility = FactoryBot.create(:facility, :seed, facility_attrs)
          FactoryBot.create_list(:user, number_of_users,
            :with_phone_number_authentication,
            registration_facility: facility,
            organization: organization,
            role: ENV["SEED_GENERATED_ACTIVE_USER_ROLE"])
        end
      end
    end

    # DH is one per facility group
    # all other larges are 5% per FG
    # medium is 15% per FG
    # small is 30% per FG
    # community is 50%
    def facility_size_map
      {
        "CH" => :large,
        "DH" => :large,
        "Hospital" => :large,
        "RH" => :large,
        "SDH" => :large,

        "CHC" => :medium,

        "MPHC" => :small,
        "PHC" => :small,
        "SAD" => :small,
        "Standalone" => :small,
        "UHC" => :small,
        "UPHC" => :small,
        "USAD" => :small,

        "HWC" => :community,
        "Village" => :community
      }
    end
  end
end
