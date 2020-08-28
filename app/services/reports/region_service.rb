module Reports
  class RegionService
    MAX_MONTHS_OF_DATA = 24

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
      result.merge! CohortService.new(region: region, quarters: last_five_quarters).call
      result.visited_without_bp_taken = NoBPMeasureService.new(region, periods: range).call
      result.calculate_percentages(:visited_without_bp_taken)
      result.count_missed_visits
      result.calculate_missed_visits_percentages

      result
    end

    private

    # We want the current quarter and then the previous four
    def last_five_quarters
      period.to_quarter_period.value.downto(4)
    end
  end
end
