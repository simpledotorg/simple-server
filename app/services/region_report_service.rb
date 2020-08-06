class RegionReportService
  include SQLHelpers
  MAX_MONTHS_OF_DATA = 24
  CACHE_VERSION = 4

  def initialize(region:, period:, current_user:)
    @current_user = current_user
    @organizations = Pundit.policy_scope(current_user, [:cohort_report, Organization]).order(:name)
    @region = region
    @period = period
    @facilities = region.facilities
    @data = {
      controlled_patients: {},
      registrations: {},
      cumulative_registrations: 0,
      quarterly_registrations: [],
      top_region_benchmarks: {}
    }.with_indifferent_access
  end

  attr_reader :current_user
  attr_reader :data
  attr_reader :facilities
  attr_reader :organizations
  attr_reader :period
  attr_reader :region

  def call
    compile_control_and_registration_data
    data.merge! compile_cohort_trend_data
    data[:top_region_benchmarks].merge!(top_region_benchmarks)

    data
  end

  def compile_control_and_registration_data
    start_period = period.advance(months: -(MAX_MONTHS_OF_DATA - 1))
    periods = start_period..@period
    result = ControlRateService.new(region, periods: periods).call
    @data.merge! result
  end

  # We want to return cohort data for the current quarter for the selected date, and then
  # the previous three quarters.
  def compile_cohort_trend_data
    Rails.cache.fetch(cohort_cache_key, version: cohort_cache_version, expires_in: 7.days, force: force_cache?) do
      CohortService.new(region: region, quarters: period.to_quarter_period.value.downto(3)).call
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
