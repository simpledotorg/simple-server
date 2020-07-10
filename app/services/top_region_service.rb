# Currently this object returns the "top district (aka facility group)" by control rate from a set of organizations.
class TopRegionService
  def initialize(organizations, date, scope: :facility_group, force_cache: false)
    unless scope.in?([:facility_group, :facility])
      raise ArgumentError, "scope is #{scope} but must be one of :facility_group or :facility"
    end
    @force_cache = force_cache
    @organizations = organizations
    @date = date
    @scope = scope
  end

  attr_reader :date
  attr_reader :force_cache
  attr_reader :organizations
  attr_reader :scope

  def call
    accessible_regions = if scope == :facility_group
      organizations.flat_map { |org| org.facility_groups }
    else
      organizations.flat_map { |org| org.facilities }
    end
    regions_by_rate = accessible_regions.each_with_object({}) { |region, hsh|
      result = ControlRateService.new(region, date: date, force_cache: force_cache).call
      hsh[region] = result[:controlled_patients_rate][date.to_s(:month_year)]
    }
    region, percentage = regions_by_rate.max_by { |region, rate| rate }
    {
      region: region,
      district: region,
      controlled_percentage: percentage
    }
  end
end
