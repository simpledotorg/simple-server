class RegionIntegrityCheck
  def self.sweep
    new.sweep
  end

  def sweep
    resources.each do |name, resource|
      log(:info, "Sweeping for – #{name}")
      result = Result.check(resource)
      report_errors(result.inconsistencies.merge(name: name)) unless result.ok?
    end
  end

  private

  def resources
    {
      organizations: organizations,
      facilities: facilities,
      facility_groups: facility_groups,
      blocks: blocks,
      states: states
    }
  end

  def organizations
    {
      source: Organization.pluck(:id),
      region: Region.organization_regions.pluck(:source_id)
    }
  end

  def facilities
    {
      source: Facility.pluck(:id),
      region: Region.facility_regions.pluck(:source_id)
    }
  end

  def facility_groups
    {
      source: FacilityGroup.pluck(:id),
      region: Region.district_regions.pluck(:id)
    }
  end

  def blocks
    {
      source: Facility.pluck(:block, :facility_group_id).uniq.map(&:first),
      region: Region.block_regions.pluck(:name)
    }
  end

  def states
    {
      source: Facility.pluck(:state, :facility_group_id).uniq.map(&:first),
      region: Region.state_regions.pluck(:name)
    }
  end

  def report_errors(*args)
    log(:error, *args)
    sentry(*args)
  end

  def log(type, *args)
    Rails.logger.public_send(type, msg: args, class: self.class.name)
  end

  def sentry(*args)
    Raven.capture_message("Missing Region", logger: "logger", extra: args, tags: {type: "regions"})
  end

  Result = Struct.new(:source, :region) do
    def self.check(resource)
      new(resource).check
    end

    attr_reader :inconsistencies

    def initialize(resource)
      super(resource[:source], resource[:region])
      @inconsistencies = {
        missing_regions: [],
        missing_sources: []
      }
    end

    def check
      set_inconsistencies unless ok?
      self
    end

    def ok?
      source.to_set == region.to_set
    end

    private

    attr_writer :inconsistencies

    def set_inconsistencies
      sources_without_regions = source - region
      regions_without_sources = region - source

      @inconsistencies[:missing_regions] << sources_without_regions
      @inconsistencies[:missing_sources] << regions_without_sources
    end
  end
end
