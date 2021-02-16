module Reports
  class Repository
    def initialize(regions, periods:, with_exclusions: false)
      @regions = Array(regions)
      @regions_by_id = @regions.group_by { |r| r.id }
      @with_exclusions = with_exclusions

      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods.to_a
      end
    end

    attr_reader :regions, :periods
    attr_reader :regions_by_id
    attr_reader :with_exclusions

    delegate :cache, :logger, to: Rails
    def for_region_and_period(region, period)
      raise ArgumentError, "Repository does not include region #{region.slug}" unless regions.include?(region)
      raise ArgumentError, "Repository does not include period #{period}" unless periods.include?(period)
      RegionAndPeriodFetcher.new(self, region, period)
    end

    # Returns assigned patients for a region. NOTE: We grab and cache ALL the counts for a particular region with one SQL query
    # because it is easier and fast enough to do so. We still return _just_ the periods the Repository was created with
    # to conform to the same interface as all the other queries here.

    # Returns a Hash in the shape of:
    # {
    #    region_slug: { period: value, period: value },
    #    region_slug: { period: value, period: value }
    # }
    def assigned_patients_count
      full_assigned_patients_counts.each_with_object({}) do |(item, result), results|
        values = periods.each_with_object({}) { |period, region_result| region_result[period] = result[period] }
        results[item.region.slug] = values
      end
    end

    def full_assigned_patients_counts
      items = regions.map { |region| RegionItem.new(region, :cumulative_assigned_patients_count, with_exclusions: with_exclusions) }
      cache.fetch_multi(*items, force: force_cache?) { |item|
        AssignedPatientsQuery.new.count(item.region, :month, with_exclusions: with_exclusions)
      }
    end

    def cumulative_assigned_patients_count
      full_assigned_patients_counts.each_with_object({}) do |(region_item, region_values), totals|
        region_slug = region_item.region.slug
        totals[region_slug] = Hash.new(0)
        first_period = region_values.keys.first
        full_range = (first_period..periods.end)
        full_range.each do |period|
          previous_total = totals[region_slug][period.previous]
          current_amount = region_values[period] || 0
          totals[region_slug][period] += previous_total + current_amount
        end
      end
    end

    def controlled_patients_count
      cached_query(:controlled_patients_count) do |item|
        control_rate_query.controlled(item.region, item.period, with_exclusions: with_exclusions).count
      end
    end

    def controlled_patient_rates
      cached_query(:controlled_patient_rates) do |item|
        controlled = controlled_patients_count[item.region.slug][item.period]
        total = cumulative_assigned_patients_count[item.region.slug].fetch(item.period)
        percentage(controlled, total)
      end
    end

    PERCENTAGE_PRECISION = 0

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
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

    private

    # Generate all necessary cache keys for a calculation, then yield to the block with every Item.
    # Once all results are returned via fetch_multi, return the data in a standard format of:
    #   {
    #     region_1_slug: { period_1: value, period_2: value }
    #     region_2_slug: { period_1: value, period_2: value }
    #   }
    #
    def cached_query(calculation, &block)
      items = cache_keys(calculation)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |item|
        block.call(item)
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def cache_keys(calculation)
      combinations = regions.to_a.product(periods.to_a)
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
