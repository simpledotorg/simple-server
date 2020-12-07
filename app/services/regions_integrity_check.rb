class RegionsIntegrityCheck
  SENTRY_ERROR_TITLE = "Regions Integrity Failure"

  def self.sweep
    new.sweep
  end

  attr_reader :errors

  def initialize
    @errors = {}
  end

  def sweep
    resources.each do |name, resource|
      log(:info, "Sweeping for – #{name}")
      result = Result.check(resource)
      errors[name] = result.inconsistencies unless result.ok?
    end

    report_errors
    self
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
      region: Region.district_regions.pluck(:source_id)
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

  def report_errors
    return if @errors.blank?

    log(:error, @errors)
    sentry(@errors)
  end

  def log(type, *args)
    Rails.logger.public_send(type, msg: args, class: self.class.name)
  end

  def sentry(*args)
    Raven.capture_message(SENTRY_ERROR_TITLE, logger: "logger", extra: args, tags: {type: "regions"})
  end

  Result = Struct.new(:source, :region) {
    def self.check(resource)
      new(resource).check
    end

    attr_reader :inconsistencies

    def initialize(resource)
      super(resource[:source], resource[:region])
      @inconsistencies = init_inconsistencies
      @checked = false
    end

    def check
      set_inconsistencies
      @checked = true
      self
    end

    def ok?
      @checked && (@inconsistencies == init_inconsistencies)
    end

    private

    attr_writer :inconsistencies

    def set_inconsistencies
      @inconsistencies[:missing_regions] += sources_without_regions
      @inconsistencies[:missing_sources_count] = regions_without_sources_count
    end

    def sources_without_regions
      (source.to_set - region.to_set).to_a
    end

    def regions_without_sources_count
      if region.uniq.count > source.uniq.count
        (region.to_set - source.to_set).count
      else
        0
      end
    end

    def init_inconsistencies
      {
        missing_regions: [],
        missing_sources_count: 0
      }
    end
  }
end
