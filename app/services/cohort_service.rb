class CohortService
  attr_reader :region, :quarters
  CACHE_VERSION = 1
  CACHE_TTL = 7.days

  def initialize(region:, quarters: nil)
    @region = region
    @quarters = quarters || default_quarters
  end

  # Each quarter cohort is made up of patients registered in the previous quarter
  # who has had a follow up visit in the current quarter.
  def call
    result = {quarterly_registrations: []}
    quarters.each do |results_quarter|
      quarter_data = compute_quarter(results_quarter)
      result[:quarterly_registrations] << quarter_data
    end
    result
  end

  private

  def compute_quarter(results_quarter)
    Rails.cache.fetch(cache_key(results_quarter), version: cache_version, expires_in: CACHE_TTL, force: force_cache?) do
      cohort_quarter = results_quarter.previous_quarter
      period = {cohort_period: :quarter,
                registration_quarter: cohort_quarter.number,
                registration_year: cohort_quarter.year}
      query = MyFacilities::BloodPressureControlQuery.new(facilities: region.facilities, cohort_period: period)
      {
        results_in: results_quarter.to_s,
        patients_registered: cohort_quarter.to_s,
        registered: query.cohort_patients.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count
      }.with_indifferent_access
    end
  end

  def default_quarters
    Quarter.new(date: Date.current).downto(3)
  end

  def cache_key(quarter)
    "#{self.class}/#{region.model_name}/#{region.id}/#{quarter}"
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
