module MonthlyDistrictReport
  class FacilityData
    attr_reader :repo, :district, :month

    def initialize(district, period_month)
      @district = district
      @month = period_month
      @repo = Reports::Repository.new(district.facility_regions, periods: period_month)
    end

    def content_rows
      district
        .facility_regions
        .joins("INNER JOIN reporting_facilities on reporting_facilities.facility_id = regions.source_id")
        .select("regions.*, reporting_facilities.*")
        .order(:block_name, :facility_name)
        .map.with_index do |facility_region, index|
        row_data(facility_region, index)
      end
    end

    def header_rows
      [[
        "Sl.No",
        "Facility size",
        "Name of facility",
        "Name of block",
        "Total registrations",
        "Patients under care",
        "Registrations this month",
        "BP control % of all patients registered before 3 months"
      ]]
    end

    private

    def row_data(facility_region, index)
      facility = facility_region.source
      {
        "Sl.No" => index + 1,
        "Facility size" => facility.localized_facility_size,
        "Name of facility" => facility.name,
        "Name of block" => facility_region.block_name,
        "Total registrations" => repo.cumulative_registrations[facility_region.slug][month],
        "Patients under care" => repo.under_care[facility_region.slug][month],
        "Registrations this month" => repo.monthly_registrations[facility_region.slug][month],
        "BP control % of all patients registered before 3 months" => repo.controlled_rates[facility_region.slug][month]
      }
    end
  end
end
