require_dependency "seed/config"

module Seed
  class FacilitySeeder
    FACILITY_SIZE_WEIGHTS = {
      community: 0.50,
      small: 0.30,
      medium: 0.15,
      large: 0.05
    }.freeze

    SIZES_TO_TYPE = {
      large: ["CH", "DH", "Hospital", "RH", "SDH"],
      medium: ["CHC"],
      small: ["MPHC", "PHC", "SAD", "Standalone", "UHC", "UPHC", "USAD"],
      community: ["HWC", "Village"]
    }

    # The max number of facilities in a block in a facility group.
    MAX_FACILITIES_PER_BLOCK = 3.0

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

    def weighted_facility_size_sample
      FACILITY_SIZE_WEIGHTS.max_by { |_, weight| rand**(1.0 / weight) }.first
    end

    def facilities_per_block
      max_number_facilities_per_block = (number_of_facilities_per_facility_group / MAX_FACILITIES_PER_BLOCK).ceil
      config.rand_or_max(1..max_number_facilities_per_block)
    end

    def call
      Region.root || Region.create!(name: "India", region_type: Region.region_types[:root], path: "india")
      organization = Seed.seed_org

      if number_of_facility_groups <= FacilityGroup.count
        puts "Not creating FacilityGroups or Facilities, we already have max # (#{number_of_facility_groups}) of FacilityGroups"
        return
      end
      puts "Creating #{number_of_facility_groups} FacilityGroups..."

      facility_groups = number_of_facility_groups.times.map {
        state_region = FactoryBot.create(:region, :state, name: Seed::FakeNames.instance.state, reparent_to: organization.region)
        FactoryBot.build(:facility_group, organization_id: organization.id, state: state_region.name)
      }
      fg_result = FacilityGroup.import_with_regions(facility_groups, returning: [:id, :name], on_duplicate_key_ignore: true)

      facility_attrs = []
      fg_result.results.each do |row|
        facility_group_id, facility_group_name = *row
        fg_region = Region.find(facility_group_id)
        state_region = fg_region.state_region
        number_facilities = number_of_facilities_per_facility_group
        blocks = Seed::FakeNames.instance.blocks.sample(facilities_per_block)
        number_facilities.times {
          size = weighted_facility_size_sample
          type = SIZES_TO_TYPE.fetch(size).sample
          block_region = FactoryBot.create(:region, :block, name: blocks.sample, reparent_to: fg_region)

          # TODO set the facility state here to match the parent district!
          # also, what about ze blocks?
          attrs = {
            district: facility_group_name,
            facility_group_id: facility_group_id,
            facility_size: size,
            facility_type: type,
            state: state_region.name,
            zone: block_region.name
          }
          facility_attrs << FactoryBot.build(:facility, :seed, attrs)
        }
      end

      Facility.import_with_regions(facility_attrs, on_duplicate_key_ignore: true)
    end
  end
end
