# An Item is a specific calculation for a Region at a specific Period
module Reports
  class Item
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

    alias_method :to_s, :cache_key
  end
end
