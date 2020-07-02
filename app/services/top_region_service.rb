class TopRegionService
  def initialize(organizations, date)
    @organizations = organizations
    @date = date
  end

  attr_reader :date
  attr_reader :organizations

  def call
    districts_by_rate = organizations.flat_map { |o| o.facility_groups }.each_with_object({}) { |district, hsh|
      controlled = ControlledPatientsQuery.call(facilities: district.facilities, time: date).count
      registration_count = Patient.with_hypertension
        .where(registration_facility: district.facilities)
        .where("recorded_at <= ?", date).count
      hsh[district] = percentage(controlled, registration_count)
    }
    district, percentage = districts_by_rate.max_by { |district, rate| rate }
    {
      district: district,
      controlled_percentage: percentage
    }
  end

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    (numerator.to_f / denominator) * 100
  end
end
