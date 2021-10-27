class CohortService
  include BustCache
  CACHE_VERSION = 3
  CACHE_TTL = 7.days
  attr_reader :periods
  attr_reader :region
  attr_reader :region_field
  attr_reader :reporting_schema_v2

  def initialize(region:, periods:, reporting_schema_v2: RequestStore.store[:reporting_schema_v2])
    @region = region.region
    @periods = periods
    @reporting_schema_v2 = reporting_schema_v2
    @region_field = "#{@region.region_type}_region_id"
  end

  COUNTS = %i[
    quarterly_cohort_controlled
    quarterly_cohort_missed_visit
    quarterly_cohort_patients
    quarterly_cohort_uncontrolled
  ]
  # SUMS = COUNTS.map { |field| Arel.sql("COALESCE(SUM(#{field}::int), 0) as #{field}") }
  SUMS = COUNTS.map { |field| Arel.sql("SUM(#{field}::int) as #{field}") }

  def call
    if reporting_schema_v2
      periods.each_with_object([]) do |period, arry|
        quarter_string = "#{period.value.year}-#{period.value.number}"
        cohort_period = period.previous
        stats = Reports::QuarterlyFacilityState.where(facility: region.facilities, quarter_string: quarter_string)
          .group(region_field, :quarter_string)
          .select(:quarter_string, region_field, SUMS)
        stat = stats.all[0]

        arry << {
          controlled: stat.quarterly_cohort_controlled,
          no_bp: stat.quarterly_cohort_missed_visit,
          patients_registered: cohort_period.to_s,
          registered: stat.quarterly_cohort_patients,
          results_in: period.to_s,
          uncontrolled: stat.quarterly_cohort_uncontrolled
        }.with_indifferent_access
      end
    else
      periods.each_with_object([]) do |period, arry|
        arry << compute(period)
      end
    end
  end

  private

  def compute(period)
    Rails.cache.fetch(cache_key(period), version: cache_version, expires_in: CACHE_TTL, force: bust_cache?) do
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
      query = ControlRateCohortQuery.new(facilities: region.facilities, cohort_period: hsh)
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
    "#{self.class}/#{region.cache_key}/#{period.cache_key}"
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end
end
