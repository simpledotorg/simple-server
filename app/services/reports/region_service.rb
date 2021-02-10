module Reports
  class RegionService
    MAX_MONTHS_OF_DATA = 24

    # The default period we report on is the current month.
    def self.default_period
      Period.month(Date.current.beginning_of_month)
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(region:, period:, with_exclusions: false, months: MAX_MONTHS_OF_DATA)
      @current_user = current_user
      @region = region
      @period = period
      start_period = period.advance(months: -(months - 1))
      @range = Range.new(start_period, @period)
      @with_exclusions = with_exclusions
    end

    attr_reader :current_user
    attr_reader :result
    attr_reader :period
    attr_reader :range
    attr_reader :region
    attr_reader :with_exclusions

    def call
      result = ControlRateService.new(region, periods: range, with_exclusions: with_exclusions).call
      result.visited_without_bp_taken = repository.no_bp_measure_count[region.slug]
      result.calculate_percentages(:visited_without_bp_taken)

      start_period = [result.earliest_registration_period, range.begin].compact.max
      calc_range = (start_period..range.end)
      result.calculate_missed_visits(calc_range)
      result.calculate_missed_visits_percentages(calc_range)
      result.calculate_period_info(calc_range)

      result
    end

    private

    def repository
      @repository ||= Reports::Repository.new(region, periods: range, with_exclusions: with_exclusions)
    end

    # We want the current quarter and then the previous four
    def last_five_quarters
      period.to_quarter_period.value.downto(4)
    end
  end
end
