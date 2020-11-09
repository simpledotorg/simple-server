class RegionBackfill
  def self.call(*args)
    new(*args).call
  end

  class UnsupportedCountry < RuntimeError; end

  attr_reader :logger
  attr_reader :invalid_counts
  attr_reader :success_counts

  def initialize(dry_run: true)
    @dry_run = dry_run
    @write = !@dry_run
    @logger = Rails.logger.child(class: self.class.name, dry_run: dry_run)
    @success_counts = {}
    @invalid_counts = {}
  end

  def dry_run?
    @dry_run
  end

  def write?
    @write
  end

  def call
    create_regions
    logger.info msg: "complete", success_counts: success_counts, invalid_counts: invalid_counts
  end

  NullRegion = Struct.new(:name, keyword_init: true) {
    def path
      nil
    end

    def children
      Region.all
    end
  }

  def create_regions
    current_country_name = CountryConfig.current[:name]
    if current_country_name != "India" && !dry_run?
      raise UnsupportedCountry, "#{self.class.name} not yet ready to run in write mode in #{current_country_name}"
    end
    root_type = "root"
    org_type = "organization"
    state_type = "state"
    district_type = "district"
    block_type = "block"
    facility_type = "facility"

    root_parent = NullRegion.new(name: "__null_region__")
    instance = find_or_create_region_from name: current_country_name, region_type: root_type, parent: root_parent

    Organization.all.each do |org|
      org_region = find_or_create_region_from(source: org, region_type: org_type, parent: instance)

      state_names = org.facilities.distinct.pluck(:state)
      states = state_names.each_with_object({}) { |name, hsh|
        hsh[name] = find_or_create_region_from(name: name, region_type: state_type, parent: org_region)
      }

      org.facilities.order(:slug).find_each do |facility|
        state = states.fetch(facility.state) { |name| "Could not find state #{name}" }
        facility_group = facility.facility_group
        district = find_or_create_region_from(source: facility_group, region_type: district_type, parent: state)
        if facility.block.blank?
          count_invalid(block_type)
          logger.info msg: "Skipping creation of Facility #{facility.name} because the block field (ie zone) is blank",
                      error: "block is blank",
                      block_name: facility.block,
                      facility: facility.name
          next
        end
        block_region = find_or_create_region_from(name: facility.block, region_type: block_type, parent: district)
        find_or_create_region_from(source: facility, region_type: facility_type, parent: block_region)
      end
    end
  end

  def find_or_create_region_from(parent:, region_type:, name: nil, source: nil)
    raise ArgumentError, "Provide either a name or a source" if (name && source) || (name.blank? && source.blank?)
    region_name = name || source.name

    existing_region = parent.children.find_by(name: region_name, region_type: region_type)
    return existing_region if existing_region

    region = DryRunRegion.new(Region.new(name: region_name, region_type: region_type, reparent_to: parent), dry_run: dry_run?, logger: logger)
    if source
      region.source = source
      # Attempt to set the slug on the region the same as the source -- we are using FriendlyId's set_slug
      # so that the built-in uniqueness logic will work for duplicates.
      region.set_slug(source.slug)
    end

    if region.save_or_check_validity
      count_success(region_type)
    else
      count_invalid(region_type)
    end
    region
  end

  def count_success(region_type)
    success_counts[region_type] ||= 0
    success_counts[region_type] += 1
  end

  def count_invalid(region_type)
    invalid_counts[region_type] ||= 0
    invalid_counts[region_type] += 1
  end
end
