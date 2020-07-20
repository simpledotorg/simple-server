# Currently this object returns the "top district (aka facility group)" by control rate from a set of organizations.
class TopRegionService
  def initialize(organizations, date, scope: :facility_group)
    unless scope.in?([:facility_group, :facility])
      raise ArgumentError, "scope is #{scope} but must be one of :facility_group or :facility"
    end
    @organizations = organizations
    @date = date
    @scope = scope
    @formatted_date = date.to_s(:month_year)
  end

  attr_reader :date
  attr_reader :formatted_date
  attr_reader :organizations
  attr_reader :scope

  def call
    accessible_regions = if scope == :facility_group
      organizations.flat_map { |org| org.facility_groups }
    else
      organizations.flat_map { |org| org.facilities }
    end
    all_region_data = accessible_regions.each_with_object({}) { |region, hsh|
      result = ControlRateService.new(region, date: date).call
      hsh[region] = result
    }
    top_region_for_rate, control_rate_result = all_region_data.max_by { |region, result|
      result[:controlled_patients_rate][formatted_date]
    }
    top_region_for_registrations, registrations_result = all_region_data.max_by { |region, result|
      result[:registrations][formatted_date]
    }
    {
      region: top_region_for_rate,
      district: top_region_for_rate,
      controlled_percentage: control_rate_result[:controlled_patients_rate][formatted_date],
      registrations: {
        region: top_region_for_registrations,
        value: registrations_result[:registrations][formatted_date]
      }
    }
  end
end
