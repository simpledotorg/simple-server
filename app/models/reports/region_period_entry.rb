module Reports
  class RegionPeriodEntry
    attr_reader :region, :period, :calculation

    def initialize(region, period, calculation, **options)
      @region = region
      @period = period
      @calculation = calculation
      @options = options.to_a
    end

    def cache_key
      [region.cache_key, period.cache_key, calculation, @options].join("/")
    end

    delegate :adjusted_period, to: :period
    delegate :slug, to: :region
    alias_method :to_s, :cache_key
  end
end
