# Currently this object returns the "top district (aka facility group)" by control rate from a set of organizations.
class TopRegionService
  def initialize(organizations, date)
    @organizations = organizations
    @date = date
  end

  attr_reader :date
  attr_reader :organizations

  def call
    districts_by_rate = organizations.flat_map { |o| o.facility_groups }.each_with_object({}) { |district, hsh|
      result = ControlRateService.new(district, date: date).call
      hsh[district] = result[:controlled_patients_rate][date.to_s(:month_year)]
    }
    district, percentage = districts_by_rate.max_by { |district, rate| rate }
    {
      district: district,
      controlled_percentage: percentage
    }
  end
end
