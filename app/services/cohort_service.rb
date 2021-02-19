class CohortService
  CACHE_VERSION = 2
  CACHE_TTL = 7.days
  attr_reader :periods
  attr_reader :region

  def initialize(region:, periods:, with_exclusions: false)
    @region = region
    @periods = periods
    @with_exclusions = with_exclusions
  end

  def call
    periods.each_with_object([]) do |period, arry|
      arry << compute(period)
    end
  end

  private

  def compute(period)
    Rails.cache.fetch(cache_key(period), version: cache_version, expires_in: CACHE_TTL, force: force_cache?) do
      cohort_period = period.previous
      results_in = if period.quarter?
        period.to_s
      else
        [period, period.next].map { |p| p.value.strftime("%b") }.join("/")
      end
      hsh = {cohort_period: cohort_period.type,
             registration_quarter: cohort_period.value.try(:number),
             registration_year: cohort_period.value.try(:year),
             registration_month: cohort_period.value.try(:month)}
      query = BloodPressureControlQuery.new(facilities: region.facilities, cohort_period: hsh, with_exclusions: @with_exclusions)
      {
        results_in: results_in,
        patients_registered: cohort_period.to_s,
        registered: query.cohort_patients.count,
        controlled: query.cohort_controlled_bps.count,
        no_bp: query.cohort_missed_visits_count,
        uncontrolled: query.cohort_uncontrolled_bps.count
      }.with_indifferent_access
    end
  end

  def default_range
    Quarter.new(date: Date.current).downto(3)
  end

  def cache_key(period)
    if @with_exclusions
      "#{self.class}/#{region.cache_key}/#{period.cache_key}/with_exclusions"
    else
      "#{self.class}/#{region.cache_key}/#{period.cache_key}"
    end
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
