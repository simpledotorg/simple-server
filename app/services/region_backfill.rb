class RegionBackfill
  def self.call(*args)
    new(*args).call
  end

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

  def create_regions
    root_type = find_region_type("Root")
    org_type = find_region_type("Organization")
    facility_group_type = find_region_type("FacilityGroup")
    block_type = find_region_type("Block")
    facility_type = find_region_type("Facility")

    current_country_name = CountryConfig.current[:name]
    instance = create_or_fake_object name: current_country_name, path: current_country_name, type: root_type

    Organization.all.each do |org|
      org_region = create_region_from(source: org, region_type: org_type, parent: instance)

      org.facility_groups.each do |facility_group|
        facility_group_region = create_region_from(source: facility_group, region_type: facility_group_type, parent: org_region)

        facility_group.facilities.group_by(&:zone).each do |block_name, facilities|
          if block_name.blank?
            count_invalid(block_type)
            logger.info msg: "skip_block", error: "block_name is blank", block_name: block_name, facilities: facilities.map(&:name)
            next
          end
          block_region = create_region_from(name: block_name, region_type: block_type, parent: facility_group_region)
          facilities.each do |facility|
            create_region_from(source: facility, region_type: facility_type, parent: block_region)
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
      root = RegionType.create! name: "Root", path: "Root"
      org = RegionType.create! name: "Organization", parent: root
      facility_group = RegionType.create! name: "FacilityGroup", parent: org
      block = RegionType.create! name: "Block", parent: facility_group
      _facility = RegionType.create! name: "Facility", parent: block
    end
    root
  end

  def create_or_fake_object(attrs)
    region = Region.new(attrs)
    logger.info msg: "create", region: region.log_payload
    unless dry_run?
      region.save!
    end
    region
  end

  def create_region_from(parent:, region_type:, name: nil, source: nil)
    logger.info msg: "create_region_from", parent: parent.name, type: region_type.name, name: name, source: source
    raise ArgumentError, "Provide either a name or a source" if (name && source) || (name.blank? && source.blank?)
    region_name = name || source.name
    region = Region.new name: region_name, type: region_type
    region.send :set_slug
    region.source = source if source
    region.path = "#{parent.path}.#{region.name_to_path_label}"

    logger.info msg: "create", region: region.log_payload
    if dry_run?
      if region.valid?
        count_success(region_type)
      else
        count_invalid(region_type)
      end
    else
      if region.save
        count_success(region_type)
      else
        count_invalid(region_type)
      end
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
