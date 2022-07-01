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

  def diabetes_content_rows
    district_facility_regions
      .filter { |facility_region| facility_region.diabetes_management_enabled? }
      .map.with_index do |facility_region, index|
      {
        "Sl.No" => index + 1,
        "Facility size" => facility.localized_facility_size,
        "Name of facility" => facility.name,
        "Name of block" => facility_region.block_name,
        "Total diabetes registrations" => repo.cumulative_diabetes_registrations[facility_region.slug][month],
        "Diabetes patients under care" => repo.adjusted_diabetes_patients[facility_region.slug][month],
        "Diabetes patients registered this month" => repo.monthly_diabetes_registrations[facility_region.slug][month],
        "Blood sugar < 200 % of all patients registered before 3 months" => percentage_string(repo.bs_below_200_rates[facility_region.slug][month]),
        "Blood sugar between 200 and 300 % of all patients registered before 3 months" => percentage_string(repo.bs_below_200_rates[facility_region.slug][month]),
        "Blood sugar over 300 % of all patients registered before 3 months" => percentage_string(repo.bs_over_300_rates[facility_region.slug][month])
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

  def diabetes_header_rows
    [[
      "Sl.No",
      "Facility size",
      "Name of facility",
      "Name of block",
      "Total diabetes registrations",
      "Diabetes patients under care",
      "Diabetes patients registered this month",
      "Blood sugar < 200 % of all patients registered before 3 months",
      "Blood sugar between 200 and 300 % of all patients registered before 3 months",
      "Blood sugar over 300 % of all patients registered before 3 months"
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
