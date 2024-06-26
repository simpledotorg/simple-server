class MonthlyDistrictReport::Hypertension::FacilityData
  include MonthlyDistrictReport::Utils
  attr_reader :repo, :district, :month

  def initialize(district, period_month)
    @district = district
    @month = period_month
    @repo = Reports::Repository.new(district.facility_regions, periods: period_month)
  end

  def content_rows
    district_facility_regions
      .map.with_index do |facility_region, index|
      facility = facility_region.source
      {
        "Sl.No" => index + 1,
        "Facility size" => facility.localized_facility_size,
        "Name of facility" => facility.name,
        "Name of block" => facility_region.block_name,
        "Total hypertension registrations" => repo.cumulative_registrations[facility_region.slug][month],
        "Hypertension patients under care" => repo.adjusted_patients[facility_region.slug][month],
        "Hypertension patients registered this month" => repo.monthly_registrations[facility_region.slug][month],
        "BP control % of all patients registered before 3 months" => percentage_string(repo.controlled_rates[facility_region.slug][month])
      }
    end
  end

  def header_rows
    [[
      "Sl.No",
      "Facility size",
      "Name of facility",
      "Name of block",
      "Total hypertension registrations",
      "Hypertension patients under care",
      "Hypertension patients registered this month",
      "BP control % of all patients registered before 3 months"
    ]]
  end

  private

  def district_facility_regions
    active_facility_ids = district.facilities.active(month_date: @month.to_date).pluck(:id)

    district
      .facility_regions
      .where("regions.source_id" => active_facility_ids)
      .joins("INNER JOIN reporting_facilities on reporting_facilities.facility_id = regions.source_id")
      .select("regions.*, reporting_facilities.*")
      .order(:block_name, :facility_name)
  end

  def row_data(facility_region, index)
    facility = facility_region.source
    {
      "Sl.No" => index + 1,
      "Facility size" => facility.localized_facility_size,
      "Name of facility" => facility.name,
      "Name of block" => facility_region.block_name,
      "Total registrations" => repo.cumulative_registrations[facility_region.slug][month],
      "Patients under care" => repo.adjusted_patients[facility_region.slug][month],
      "Registrations this month" => repo.monthly_registrations[facility_region.slug][month],
      "BP control % of all patients registered before 3 months" => percentage_string(repo.controlled_rates[facility_region.slug][month])
    }
  end
end
