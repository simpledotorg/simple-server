class CohortService
  include BustCache
  CACHE_VERSION = 3
  CACHE_TTL = 7.days

  attr_reader :field_prefix
  attr_reader :periods
  attr_reader :region
  attr_reader :region_field
  attr_reader :reporting_schema_v2

  COUNTS = %i[
    cohort_controlled
    cohort_missed_visit
    cohort_patients
    cohort_uncontrolled
  ].freeze

  def initialize(region:, periods:, reporting_schema_v2: Reports.reporting_schema_v2?)
    @region = region.region
    @periods = periods.sort.reverse # Ensure we return data with most recent cohorts first
    @reporting_schema_v2 = reporting_schema_v2
    @region_field = "#{@region.region_type}_region_id"
    @quarterly = @periods.first.quarter?
    @field_prefix = quarterly? ? "quarterly" : "monthly"
  end

  def quarterly?
    @quarterly
  end

  def sums
    @sums ||= COUNTS.map { |field| Arel.sql("SUM(#{field_prefix}_#{field}::int) as #{field}") }
  end

  def call
    if reporting_schema_v2
      results = v2_query(periods)
      compute_v2(results)
    else
      periods.each_with_object([]) do |period, arry|
        arry << compute(period)
      end
    end
  end

  private

  def compute_v2(results)
    results.each_with_object([]) do |result, arry|
       arry << {
         controlled: result.cohort_controlled,
         no_bp: result.cohort_missed_visit,
         registration_period: result.period,
         patients_registered: result.period.advance(months: -2).to_s(:mon_year),
         registered: result.cohort_patients,
         results_in: result.period.to_s(:cohort),
         uncontrolled: result.cohort_uncontrolled
       }.with_indifferent_access
    end
  end

  def v2_query(range)
    if quarterly?
      range = range.map { |p| p.to_s(:quarter_string) }
      Reports::QuarterlyFacilityState.where(facility: region.facilities, quarter_string: range)
        .group(region_field, :quarter_string, :month_date)
        .order("quarter_string desc")
        .select(:month_date, region_field, sums)
    else
      range = periods.map { |p| p.value }
      Reports::FacilityState.where(facility: region.facilities, month_date: range)
        .group(region_field, :month_date)
        .order("month_date desc")
        .select(:month_date, region_field, sums)
    end
  end

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
