class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24
  CACHE_VERSION = 7

  def initialize(region:, period:, current_user:, top_region_benchmarks_enabled: false)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @region = region
    @period = period
    @facilities = region.facilities.to_a
    start_period = period.advance(months: -(MAX_MONTHS_OF_DATA - 1))
    @range = start_period..@period
    @top_region_benchmarks_enabled = top_region_benchmarks_enabled
    @result = Reports::Result.new(@range)
  end

  attr_reader :current_user
  attr_reader :result
  attr_reader :facilities
  attr_reader :organizations
  attr_reader :period
  attr_reader :range
  attr_reader :region

  def top_region_benchmarks_enabled?
    @top_region_benchmarks_enabled
  end

  def call
    result.merge! ControlRateService.new(region, periods: range).call
    result.merge! compile_cohort_trend_data
    result.visited_without_bp_taken = NoBPMeasureService.new(region, periods: range).call
    result.calculate_percentages(:visited_without_bp_taken)
    result.count_missed_visits
    result.missed_visits_rate = calculate_missed_visits_percentages
    # TODO refactor top region benchmarks - this isn't used right now and doesn't follow the most recent refactoring
    result[:top_region_benchmarks].merge!(top_region_benchmarks) if top_region_benchmarks_enabled?

    result
  end

  private

  # To determine the missed visits percentage, we sum the remaining percentages and subtract that from 100.
  # If we determined the percentage directly, we would have cases where the percentages do not add up to 100
  # due to rounding and losing precision.
  def calculate_missed_visits_percentages
    range.each_with_object({}) do |period, hsh|
      remaining_percentages = result[:controlled_patients_rate][period] + result[:uncontrolled_patients_rate][period] + result[:visited_without_bp_taken_rate][period]
      hsh[period] = 100 - remaining_percentages
    end
  end

  # We want to return cohort result for the current quarter for the selected date, and then
  # the previous three quarters.
  def compile_cohort_trend_data
    Rails.cache.fetch(cohort_cache_key, version: cohort_cache_version, expires_in: 7.days, force: force_cache?) do
      result = {quarterly_registrations: []}
      period.to_quarter_period.value.downto(3).each do |results_quarter|
        cohort_quarter = results_quarter.previous_quarter

        period = {cohort_period: :quarter,
                  registration_quarter: cohort_quarter.number,
                  registration_year: cohort_quarter.year}
        query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities, cohort_period: period)
        result[:quarterly_registrations] << {
          results_in: format_quarter(results_quarter),
          patients_registered: format_quarter(cohort_quarter),
          registered: query.cohort_registrations.count,
          controlled: query.cohort_controlled_bps.count,
          no_bp: query.cohort_missed_visits_count,
          uncontrolled: query.cohort_uncontrolled_bps.count
        }.with_indifferent_access
      end
      result
    end
  end

  def percentage(numerator, denominator)
    return 0 if numerator == 0 || denominator == 0
    ((numerator.to_f / denominator.to_f) * 100).round(0)
  end

  def cohort_cache_key
    "#{self.class}/cohort_trend_data/#{region.model_name}/#{region.id}/#{organizations.map(&:id)}/#{period}/#{CACHE_VERSION}"
  end

  def cohort_cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end

  def format_quarter(quarter)
    "#{quarter.year} Q#{quarter.number}"
  end

  def top_region_benchmarks
    scope = region.class.to_s.underscore.to_sym
    TopRegionService.new(organizations, period, scope: scope).call
  end
end
