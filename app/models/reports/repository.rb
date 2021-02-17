module Reports
  class Repository
    def initialize(regions, periods:, with_exclusions: false)
      @regions = Array(regions)
      @regions_by_id = @regions.group_by { |r| r.id }
      @with_exclusions = with_exclusions

      @periods = if periods.is_a?(Period)
        Range.new(periods, periods).to_a
      else
        periods.to_a
      end
    end

    attr_reader :regions, :periods
    attr_reader :regions_by_id
    attr_reader :with_exclusions

    delegate :cache, :logger, to: Rails

    def controlled_patients_count
      cached_query(:controlled_patients_count) do |item|
        control_rate_query.controlled(item.region, item.period, with_exclusions: with_exclusions).count
      end
    end

    def uncontrolled_patients_count
      cached_query(:uncontrolled_patients_count) do |item|
        control_rate_query.uncontrolled(item.region, item.period, with_exclusions: with_exclusions).count
      end
    end

    def no_bp_measure_count
      cached_query(:no_bp_measure_count) do |item|
        no_bp_measure_query.call(item.region, item.period, with_exclusions: with_exclusions)
      end
    end

    # Generate all necessary cache keys for a calculation, then yield to the block with every Item.
    # Once all results are returned via fetch_multi, return the data in a standard format of:
    #   {
    #     region_1_slug: { period_1: value, period_2: value }
    #     region_2_slug: { period_1: value, period_2: value }
    #   }
    #
    def cached_query(calculation, &block)
      items = cache_keys(calculation)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |item| block.call(item) }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def cache_keys(calculation)
      combinations = regions.to_a.product(periods)
      combinations.map { |region, period| Reports::Item.new(region, period, calculation, with_exclusions: with_exclusions) }
    end

    def no_bp_measure_query
      @query ||= NoBPMeasureQuery.new
    end

    def control_rate_query
      @control_rate_query ||= ControlRateQuery.new
    end

    def force_cache?
      RequestStore.store[:force_cache]
    end
  end
end
