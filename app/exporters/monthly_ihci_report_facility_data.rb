class MonthlyIHCIReportFacilityData
  attr_reader :repo, :district, :month

  def initialize(district, period_month)
    @district = district
    @month = period_month
    @repo = Reports::Repository.new(district.facility_regions, periods: period_month)
  end

  def generate_csv

  end

  def headers

  end

  def rows
    district
      .facility_regions
      .joins("INNER JOIN reporting_facilities on reporting_facilities.facility_id = regions.source_id")
      .select("regions.*, reporting_facilities.*")
      .map do |facility_region|
      row_data(facility_region)
    end
  end

  def row_data(facility_region)
    [facility = facility_region.source,
    facility.facility_size,
    facility.name,
    facility_region.block_name,
    repo.cumulative_registrations[facility_region.slug][month],
    repo.under_care[facility_region.slug][month],
    repo.monthly_registrations[facility_region.slug][month],
    repo.controlled_rates[facility_region.slug][month]]
  end
end