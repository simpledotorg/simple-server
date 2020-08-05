class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24
  CACHE_VERSION = 4

  def initialize(region:, period:, current_user:)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @region = region
    @period = period
    @facilities = region.facilities.to_a
    start_period = period.advance(months: -(MAX_MONTHS_OF_DATA - 1))
    @range = start_period..@period
    @data = {
      controlled_patients: {},
      cumulative_registrations: 0,
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

  def call
    compile_control_and_registration_data
    data.merge! compile_cohort_trend_data
    data[:visited_without_bp_taken] = count_visited_without_bp_taken
    data[:visited_without_bp_taken_rate] = percentage_visited_without_bp_taken
    data[:missed_visits] = calculate_missed_visits
    data[:missed_visits_rate] = calculate_missed_visits_rate
    data[:top_region_benchmarks].merge!(top_region_benchmarks)

    data
  end

  def calculate_missed_visits
    data[:cumulative_registrations].each_with_object({}) do |(period, count), hsh|
      hsh[period] = count - data[:controlled_patients][period] - data[:uncontrolled_patients][period]
    end
  end

  def calculate_missed_visits_rate
    data[:missed_visits].each_with_object({}) do |(period, count), hsh|
      hsh[period] = percentage(count, data[:cumulative_registrations][period].to_f)
    end
  end

  # visited in last 3 months but had no BP taken
  def count_visited_without_bp_taken
    periods = data[:registrations].keys
    VisitedButNoBPService.new(region, periods: periods).call
  end

  def percentage_visited_without_bp_taken
    data[:visited_without_bp_taken].each_with_object({}) do |(period, count), hsh|
      hsh[period] = percentage(count, data[:cumulative_registrations].fetch(period))
    end
  end

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    ((numerator.to_f / denominator.to_f) * 100).round(0)
  end

  def compile_control_and_registration_data
    result = ControlRateService.new(region, periods: range).call
    @data.merge! result
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters. Each quarter cohort is made up of patients registered
  # in the previous quarter who has had a follow up visit in the current quarter.
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

  private

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
