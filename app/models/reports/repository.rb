module Reports
  class Repository
    include Memery
    PERCENTAGE_PRECISION = 0

    def initialize(regions, periods:, with_exclusions: false)
      @regions = Array(regions)
      @with_exclusions = with_exclusions
      @no_bp_measure_query = NoBPMeasureQuery.new
      @control_rate_query = ControlRateQuery.new

      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods
      end
    end

    attr_reader :control_rate_query
    attr_reader :no_bp_measure_query
    attr_reader :periods
    attr_reader :regions
    attr_reader :with_exclusions

    delegate :cache, :logger, to: Rails

    # Uses Memery to memoize a method, but takes into account our force_cache setting. If force_cache is true,
    # a caller is asking for all values to be retrieved fresh from the database, so we want to skip memoization.
    def self.smart_memoize(method)
      memoize(method, condition: -> { !force_cache? })
    end

    # Returns assigned patients for a Region. NOTE: We grab and cache ALL the counts for a particular region with one SQL query
    # because it is easier and fast enough to do so. We still return _just_ the periods the Repository was created with
    # to conform to the same interface as all the other queries here.

    # Returns a Hash in the shape of:
    # {
    #    region_slug: { period: value, period: value },
    #    region_slug: { period: value, period: value }
    # }
    smart_memoize def assigned_patients_count
      complete_assigned_patients_counts.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object({}) { |period, region_result| region_result[period] = result[period] if result[period] }
        results[entry.region.slug] = values
      end
    end

    # Returns the full range of assigned patient counts for a Region. We do this via one SQL query for each Region, because its
    # fast and easy via the underlying query.
    smart_memoize def complete_assigned_patients_counts
      items = regions.map { |region| RegionEntry.new(region, :cumulative_assigned_patients_count, with_exclusions: with_exclusions) }
      cache.fetch_multi(*items, force: force_cache?) { |entry|
        AssignedPatientsQuery.new.count(entry.region, :month, with_exclusions: with_exclusions)
      }
    end

    # Return the running total of cumulative assigned patient counts.
    smart_memoize def cumulative_assigned_patients_count
      complete_assigned_patients_counts.each_with_object({}) do |(region_entry, patient_counts), totals|
        range = Range.new(patient_counts.keys.first || periods.first, periods.end)
        totals[region_entry.slug] = range.each_with_object(Hash.new(0)) { |period, sum|
          sum[period] = sum[period.previous] + patient_counts.fetch(period, 0)
        }
      end
    end

    smart_memoize def registration_counts
      complete_registration_counts.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object({}) { |period, region_result| region_result[period] = result[period] if result[period] }
        results[entry.region.slug] = values
      end
    end

    # Returns the full range of registered patient counts for a Region. We do this via one SQL query for each Region, because its
    # fast and easy via the underlying query.
    smart_memoize def complete_registration_counts
      items = regions.map { |region| RegionEntry.new(region, :cumulative_assigned_patients_count, with_exclusions: with_exclusions) }
      cache.fetch_multi(*items, force: force_cache?) { |entry|
        RegisteredPatientsQuery.new.count(entry.region, :month)
      }
    end

    smart_memoize def controlled_patients_count
      cached_query(__method__) do |entry|
        control_rate_query.controlled(entry.region, entry.period, with_exclusions: with_exclusions).count
      end
    end

    smart_memoize def uncontrolled_patients_count
      cached_query(__method__) do |entry|
        control_rate_query.uncontrolled(entry.region, entry.period, with_exclusions: with_exclusions).count
      end
    end

    smart_memoize def controlled_patient_rates
      cached_query(__method__) do |entry|
        controlled = controlled_patients_count[entry.region.slug][entry.period]
        total = cumulative_assigned_patients_count[entry.region.slug][entry.adjusted_period]
        percentage(controlled, total)
      end
    end

    smart_memoize def uncontrolled_patient_rates
      cached_query(__method__) do |entry|
        controlled = uncontrolled_patients_count[entry.region.slug][entry.period]
        total = cumulative_assigned_patients_count[entry.region.slug][entry.adjusted_period]
        percentage(controlled, total)
      end
    end

    smart_memoize def missed_visits_count
      cached_query(__method__) do |entry|
        no_bp_measure_query.call(entry.region, entry.period, with_exclusions: with_exclusions)
      end
    end

    smart_memoize def missed_visits_rate
      cached_query(__method__) do |entry|
        controlled = missed_visits_count[entry.region.slug][entry.period]
        total = cumulative_assigned_patients_count[entry.region.slug][entry.period]
        percentage(controlled, total)
      end
    end

    private

    # Generate all necessary cache keys for a calculation, then yield to the block for every entry.
    # Once all results are returned via fetch_multi, return the data in a standard format of:
    #   {
    #     region_1_slug: { period_1: value, period_2: value }
    #     region_2_slug: { period_1: value, period_2: value }
    #   }
    #
    def cached_query(calculation, &block)
      items = cache_entries(calculation)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |entry| block.call(entry) }
      cached_results.each_with_object({}) do |(entry, count), results|
        results[entry.region.slug] ||= Hash.new(0)
        results[entry.region.slug][entry.period] = count
      end
    end

    def cache_entries(calculation)
      combinations = regions.to_a.product(periods.to_a)
      combinations.map { |region, period| Reports::RegionPeriodEntry.new(region, period, calculation, with_exclusions: with_exclusions) }
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end

    def force_cache?
      RequestStore.store[:force_cache]
    end
  end
end
