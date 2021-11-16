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
    @quarterly = @periods.first.quarter?
  end

  def quarterly?
    @quarterly
  end

  COUNTS = %i[
    cohort_controlled
    cohort_missed_visit
    cohort_patients
    cohort_uncontrolled
  ]
  # SUMS = COUNTS.map { |field| Arel.sql("COALESCE(SUM(#{field}::int), 0) as #{field}") }

  def sums
    @sums ||= if quarterly?
      COUNTS.map { |field| Arel.sql("SUM(quarterly_#{field}::int) as #{field}") }
    else
      COUNTS.map { |field| Arel.sql("COALESCE(SUM(monthly_#{field}::int), 0) as #{field}") }
    end
  end

  def call
    if reporting_schema_v2
      periods.each_with_object([]) do |period, arry|
        if quarterly?
          cohort_period = period.previous
          results_in = period.to_s
        else
          cohort_period = period
          period = period.advance(months: 2)
          results_in = period.to_s(:cohort)
        end
        stats = v2_query(period)
        stat = stats.all[0]

        arry << {
          controlled: stat.cohort_controlled,
          no_bp: stat.cohort_missed_visit,
          patients_registered: cohort_period.to_s,
          registered: stat.cohort_patients,
          results_in: results_in,
          uncontrolled: stat.cohort_uncontrolled
        }.with_indifferent_access
      end
    else
      periods.each_with_object([]) do |period, arry|
        arry << compute(period)
      end
    end
  end

  private

  def v2_query(period)
    if quarterly?
      quarter_string = "#{period.value.year}-#{period.value.number}"
      Reports::QuarterlyFacilityState.where(facility: region.facilities, quarter_string: quarter_string)
        .group(region_field, :quarter_string)
        .select(:quarter_string, region_field, sums)
    else
      Reports::FacilityState.where(facility: region.facilities, month_date: period.value)
        .group(region_field, :month_date)
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
