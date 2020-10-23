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
    create_region_types
    create_regions
    logger.info msg: "complete", success_counts: success_counts, invalid_counts: invalid_counts
  end

  NullRegion = Struct.new(:name, keyword_init: true) {
    def path
      nil
    end
  }

  def create_regions
    current_country_name = CountryConfig.current[:name]
    if current_country_name != "India" && !dry_run?
      raise UnsupportedCountry, "#{self.class.name} not yet ready to run in write mode in #{current_country_name}"
    end
    root_type = find_region_type("Root")
    org_type = find_region_type("Organization")
    state_type = find_region_type("State")
    district_type = find_region_type("District")
    zone_type = find_region_type("Zone")
    facility_type = find_region_type("Facility")

    root_parent = NullRegion.new(name: "__root__")
    root_region = create_region_from name: current_country_name, region_type: root_type, parent: root_parent

    Organization.all.map do |org|
      hierarchical_facilities = org.facilities.each_with_object({}) { |facility, result|
        result[facility.state] ||= {}
        result[facility.state][facility.district] ||= {}
        result[facility.state][facility.district][facility.zone] ||= []
        result[facility.state][facility.district][facility.zone] << facility
      }

      org_region = create_region_from(source: org, region_type: org_type, parent: root_region)
      hierarchical_facilities.map do |state, districts|
        state_region = create_region_from(name: state, region_type: state_type, parent: org_region)
        districts.map do |district, zones|
          district_region = create_region_from(name: district, region_type: district_type, parent: state_region)
          zones.map do |zone, facilities|
            if zone.blank?
              count_invalid(zone_type)
              logger.info msg: "skip_zone", error: "zone_name is blank", zone_name: zone, facilities: facilities.map(&:name)
            else
              zone_region = create_region_from(name: zone, region_type: zone_type, parent: district_region)
              facilities.map do |facility|
                create_region_from(source: facility, region_type: facility_type, parent: zone_region)
              end
            end
          end
        end
      end
    end
  end

  def find_region_type(name)
    if dry_run?
      RegionType.new name: name
    else
      RegionType.find_by! name: name
    end
  end

  def create_region_types
    logger.info msg: "create_region_types"
    unless dry_run?
      RegionType::HIERARCHY.reduce(nil) do |parent_region_type, region_type|
        if !parent_region_type
          RegionType.create! name: region_type, path: region_type
        else
          RegionType.create! name: region_type, parent: parent_region_type
        end
      end
    end
  end

  def create_region_from(parent:, region_type:, name: nil, source: nil)
    logger.info msg: "create_region_from", parent: parent.name, type: region_type.name, name: name, source: source
    raise ArgumentError, "Provide either a name or a source" if (name && source) || (name.blank? && source.blank?)
    region_name = name || source.name
    region = DryRunRegion.new(Region.new(name: region_name, type: region_type), dry_run: dry_run?, logger: logger)
    region.set_slug
    region.source = source if source
    region.path = [parent.path, region.name_to_path_label].compact.join(".")

    if region.save_or_check_validity
      count_success(region_type)
    else
      count_invalid(region_type)
    end
    region
  end

  def count_success(region_type)
    success_counts[region_type.name] ||= 0
    success_counts[region_type.name] += 1
  end

  def count_invalid(region_type)
    invalid_counts[region_type.name] ||= 0
    invalid_counts[region_type.name] += 1
  end
end
