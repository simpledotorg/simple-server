module Reports
  class Repository
    def initialize(regions, periods:, with_exclusions: false)
      @regions = Array(regions)
      @regions_by_id = @regions.map { |r| [r.id, r] }.to_h
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
      items = cache_keys(:controlled_patients_count)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |item|
        control_rate_query.controlled(item.region, item.period, with_exclusions: with_exclusions).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def uncontrolled_patients_count
      items = cache_keys(:uncontrolled_patients_count)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |item|
        control_rate_query.uncontrolled(item.region, item.period, with_exclusions: with_exclusions).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def no_bp_measure_count
      query = NoBPMeasureQuery.new
      items = cache_keys(:no_bp_measure_count)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |item|
        query.call(item.region, item.period, with_exclusions: with_exclusions).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def cache_keys(calculation)
      combinations = regions.to_a.product(periods)
      combinations.map { |region, period| Reports::Item.new(region, period, calculation, with_exclusions: with_exclusions) }
    end

    def control_rate_query
      @control_rate_query ||= ControlRateQuery.new
    end

    def force_cache?
      RequestStore.store[:force_cache]
    end
  end
end
