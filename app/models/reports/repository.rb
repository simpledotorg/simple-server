module Reports
  class Repository
    def initialize(regions, periods:)
      @regions = Array(regions)
      @regions_by_id = @regions.map { |r| [r.id, r] }.to_h

      @periods = if periods.is_a?(Period)
        Range.new(periods, periods).to_a
      else
        periods.to_a
      end
    end

    attr_reader :regions, :periods
    attr_reader :regions_by_id
    delegate :cache, :logger, to: Rails
    class Item
      attr_reader :region, :period, :calculation
      def initialize(region, period, calculation)
        @region = region
        @period = period
        @calculation = calculation
      end

      def cache_key
        [region.cache_key_v2, period.cache_key, calculation].join("/")
      end
    end

    def controlled_patients_info
      items = cache_keys(:controlled_patients_info)
      cached_results = cache.fetch_multi(*items) { |item|
        query.controlled(item.region, item.period).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def uncontrolled_patients_info
      items = cache_keys(:uncontrolled_patients_info)
      cached_results = cache.fetch_multi(*items) { |item|
        query.uncontrolled(item.region, item.period).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def cache_keys(calculation)
      combinations = regions.to_a.product(periods)
      combinations.map { |region, period| Item.new(region, period, calculation) }
    end

    def query
      @query ||= ControlRateQuery.new
    end

  end
end
