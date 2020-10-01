class RegionBackfill
  def self.call(*args)
    new(*args).call
  end

  def initialize(dry_run: true)
    @dry_run = dry_run
    @write = !@dry_run
  end

  def dry_run?
    @dry_run
  end

  def write?
    @write
  end

  delegate :logger, to: Rails

  def call
    root_kind = RegionKind.find_by!(name: "Root")
    org_kind = root_kind.children.first
    facility_group_kind = org_kind.children.first
    block_kind = facility_group_kind.children.first
    facility_kind = block_kind.children.first

    current_country_name = CountryConfig.current[:name]
    instance = create_or_fake_object name: current_country_name, path: current_country_name, kind: root_kind

    Organization.all.each do |org|
      org_region = create_region_from(source: org, kind: org_kind, parent: instance)

      org.facility_groups.each do |facility_group|
        facility_group_region = create_region_from(source: facility_group, kind: facility_group_kind, parent: org_region)

        facility_group.facilities.group_by(&:zone).each do |block_name, facilities|
          block_region = create_region_from(name: block_name, kind: block_kind, parent: facility_group_region)
          facilities.each do |facility|
            create_region_from(source: facility, kind: facility_kind, parent: block_region)
          end
        end
      end
    end
  end

  def create_or_fake_object(attrs)
    if write?
      Region.create! attrs
    else
      region = Region.new attrs
      logger.info msg: "create", region: region.dry_run_info
      region
    end
  end

  def create_region_from(parent:, kind:, name: nil, source: nil)
    raise ArgumentError, "Provide either a name or a source" if (name && source) || (name.blank? && source.blank?)
    region_name = name || source.name
    region = Region.new name: region_name, kind: kind
    region.send :set_slug
    region.source = source if source
    region.path = "#{parent.path}.#{region.slug.tr("-", "_")}"
    if dry_run?
      logger.tagged(class: self.class.name) { logger.info msg: "save", region: region.dry_run_info }
    else
      region.save!
    end
    region
  end
end