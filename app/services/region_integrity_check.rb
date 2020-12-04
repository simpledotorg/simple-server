class RegionIntegrityCheck
  def self.sweep(*args)
    new(*args).sweep
  end

  class MissingRegion < RuntimeError; end

  def initialize(*args) end

  def sweep
    {
      organizations: organizations?,
      facilities: facilities?,
      facility_groups: facility_groups?,
      blocks: blocks?,
      states: states?
    }.each do |resource, check|
      unless check
        raise MissingRegion, "Regions for #{resource}, don't add up. This can be catastrophic."
      end
    end
  end

  private

  def organizations?
    Organization.count == Region.organization_regions.count
  end

  def facilities?
    Facility.count == Region.facility_regions.map(&:source).count
  end

  def facility_groups?
    FacilityGroup.count == Region.district_regions.count
  end

  def blocks?
    Facility.pluck(:block, :facility_group_id).uniq.count == Region.block_regions.pluck(:name).count
  end

  def states?
    Facility.pluck(:state).uniq.count == Region.state_regions.count
  end
end
