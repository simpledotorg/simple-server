require_dependency "seed/config"

module Seed
  class FacilitySeeder
    ADMIN_USER_NAME = "Admin User"
    ADMIN_USER_EMAIL = "admin@simple.org"

    FACILITY_SIZE_WEIGHTS = {
      community: 0.50,
      small: 0.30,
      medium: 0.15,
      large: 0.05
    }.freeze

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
      config.rand_or_max(1..config.max_number_of_facilities_per_facility_group)
    end

    def call
      Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
      org_name = "IHCI"
      organization = Organization.find_by(name: org_name) || FactoryBot.create(:organization, name: org_name)

      if number_of_facility_groups <= FacilityGroup.count
        puts "bailing, already have enough facility groups"
        return
      end
      puts "Creating #{number_of_facility_groups} FacilityGroups..."

      facility_groups = number_of_facility_groups.times.map {
        FactoryBot.build(:facility_group, organization_id: organization.id, state: nil)
      }
      fg_result = FacilityGroup.import(facility_groups, returning: [:id, :name], on_duplicate_key_ignore: true)

      facility_attrs = []
      fg_result.results.each do |row|
        facility_group_id, facility_group_name = *row
        number_of_facilities_per_facility_group.times {
          type = facility_size_map.keys.sample
          size = facility_size_map[type]

          attrs = {
            district: facility_group_name,
            facility_group_id: facility_group_id,
            facility_size: size,
            facility_type: type
          }
          facility_attrs << FactoryBot.build(:facility, :seed, attrs)
        }
      end

      Facility.import(facility_attrs, on_duplicate_key_ignore: true)
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
