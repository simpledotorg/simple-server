module Reports
  class RegionService
    include SQLHelpers
    MAX_MONTHS_OF_DATA = 24
    CACHE_VERSION = 9

    # THe default period we report on is the last month so we show the last full completed month of data.
    def self.default_period
      Period.month(Date.current.last_month.beginning_of_month)
    end

    def initialize(region:, period:)
      @current_user = current_user
      @region = region
      @period = period
      start_period = period.advance(months: -(MAX_MONTHS_OF_DATA - 1))
      @range = start_period..@period
      @result = Result.new(@range)
    end

    attr_reader :current_user
    attr_reader :result
    attr_reader :period
    attr_reader :range
    attr_reader :region

    def call
      result.merge! ControlRateService.new(region, periods: range).call
      result.merge! compile_cohort_trend_data
      result.visited_without_bp_taken = NoBPMeasureService.new(region, periods: range).call
      result.calculate_percentages(:visited_without_bp_taken)
      result.count_missed_visits
      result.calculate_missed_visits_percentages

      result
    end

    private

    # We want to return cohort result for the current quarter for the selected period, and then
    # the previous three quarters.
    def compile_cohort_trend_data
      Rails.cache.fetch(cohort_cache_key, version: cohort_cache_version, expires_in: 7.days, force: force_cache?) do
        CohortService.new(region: region, quarters: period.to_quarter_period.value.downto(4)).call
      end
    end

    def cohort_cache_key
      "#{self.class}/cohort_trend_data/#{region.model_name}/#{region.id}/#{period}/#{CACHE_VERSION}"
    end

    def cohort_cache_version
      "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
    end

    def force_cache?
      RequestStore.store[:force_cache]
    end
  end
end
