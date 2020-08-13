class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24
  CACHE_VERSION = 6

  def initialize(region:, period:, current_user:, top_region_benchmarks_enabled: false)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @region = region
    @period = period
    @facilities = region.facilities.to_a
    start_period = period.advance(months: -(MAX_MONTHS_OF_DATA - 1))
    @range = start_period..@period
    @top_region_benchmarks_enabled = top_region_benchmarks_enabled
    @data = {
      controlled_patients: {},
      lost_to_followup: {},
      lost_to_followup_rate: {},
      missed_visits: {},
      missed_visits_rate: {},
      quarterly_registrations: [],
      registrations: {},
      top_region_benchmarks: {}
    }.with_indifferent_access
  end

  attr_reader :current_user
  attr_reader :data
  attr_reader :facilities
  attr_reader :organizations
  attr_reader :period
  attr_reader :range
  attr_reader :region

  def top_region_benchmarks_enabled?
    @top_region_benchmarks_enabled
  end

  def call
    data.merge! ControlRateService.new(region, periods: range).call
    data.merge! compile_cohort_trend_data
    data[:visited_without_bp_taken] = NoBPMeasureService.new(region, periods: range).call
    data[:visited_without_bp_taken_rate] = calculate_percentages(data[:visited_without_bp_taken])
    data[:missed_visits] = count_missed_visits
    data[:missed_visits_rate] = calculate_missed_visits_percentages
    data[:top_region_benchmarks].merge!(top_region_benchmarks) if top_region_benchmarks_enabled?

    data
  end

  private

  # "Missed visits" is the remaining registerd patients when we subtract out the other three groups.
  def count_missed_visits
    data[:visited_without_bp_taken].each_with_object({}) do |(period, visit_count), result|
      controlled = data[:controlled_patients][period]
      uncontrolled = data[:uncontrolled_patients][period]
      registrations = data[:cumulative_registrations][period]
      result[period] = registrations - visit_count - controlled - uncontrolled
    end
  end

  # To determine the missed visits percentage, we sum the remaining percentages and subtract that from 100.
  # If we determined the percentage directly, we would have cases where the percentages do not add up to 100
  # due to rounding and losing precision.
  def calculate_missed_visits_percentages
    range.each_with_object({}) do |period, result|
      remaining_percentages = data[:controlled_patients_rate][period] + data[:uncontrolled_patients_rate][period] + data[:visited_without_bp_taken_rate][period]
      result[period] = 100 - remaining_percentages
    end
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters.
  def compile_cohort_trend_data
    Rails.cache.fetch(cohort_cache_key, version: cohort_cache_version, expires_in: 7.days, force: force_cache?) do
      CohortService.new(region: region, quarters: period.to_quarter_period.value.downto(3)).totals
    end
  end

  def calculate_percentages(result_hash)
    result_hash.each_with_object(Hash.new(0)) do |(period, count), hsh|
      hsh[period] = percentage(count, data[:cumulative_registrations][period])
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

  def top_region_benchmarks
    scope = region.class.to_s.underscore.to_sym
    TopRegionService.new(organizations, period, scope: scope).call
  end
end
