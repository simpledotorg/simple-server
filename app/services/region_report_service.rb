class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24
  CACHE_VERSION = 5

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
    data.merge! ControlRateService.new(region, periods: range).call
    data.merge! compile_cohort_trend_data
    data[:missed_visits] = NoBPMeasureService.new(region, periods: range).call
    data[:missed_visits_rate] = calc_missed_visits_rate
    data[:visited_without_bp_taken] = count_visited_without_bp_taken
    data[:visited_without_bp_taken_rate] = percentage_visited_without_bp_taken
    data[:top_region_benchmarks].merge!(top_region_benchmarks)

    data
  end

  def count_lost_to_followup
    data[:cumulative_registrations].each_with_object({}) do |(period, count), hsh|
      year_ago = period.advance(years: -1).to_date
      lost_to_followup = Patient
        .with_hypertension
        .where("patients.recorded_at <= ?", year_ago)
        .where(registration_facility: facilities)
        .includes(:latest_blood_pressures).where("blood_pressures.recorded_at <= ? OR blood_pressures.recorded_at IS NULL", year_ago)
        .references(:latest_blood_pressures)
      hsh[period] = lost_to_followup.count
    end
  end

  def calc_missed_visits_rate
    pp data
    data[:missed_visits].each_with_object({}) do |(period, missed_visits_count), hsh|
      hsh[period] = percentage(missed_visits_count, data[:cumulative_registrations][period])
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
    return 0 if numerator == 0 || denominator == 0
    ((numerator.to_f / denominator.to_f) * 100).round(0)
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters.
  def compile_cohort_trend_data
    Rails.cache.fetch(cohort_cache_key, version: cohort_cache_version, expires_in: 7.days, force: force_cache?) do
      CohortService.new(region: region, quarters: period.to_quarter_period.value.downto(3)).totals
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

  def top_region_benchmarks
    scope = region.class.to_s.underscore.to_sym
    TopRegionService.new(organizations, period, scope: scope).call
  end
end
