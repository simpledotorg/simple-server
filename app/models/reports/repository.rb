module Reports
  class Repository
    PERCENTAGE_PRECISION = 0

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

    # Returns assigned patients for a region. NOTE: We grab and cache ALL the counts for a particular region with one SQL query
    # because it is easier and fast enough to do so. We still return _just_ the periods the Repository was created with
    # to conform to the same interface as all the other queries here.

    # Returns a Hash in the shape of:
    # {
    #    region_slug: { period: value, period: value },
    #    region_slug: { period: value, period: value }
    # }
    def assigned_patients_count
      full_assigned_patients_counts.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object({}) { |period, region_result| region_result[period] = result[period] }
        results[entry.region.slug] = values
      end
    end

    def full_assigned_patients_counts
      items = regions.map { |region| RegionEntry.new(region, :cumulative_assigned_patients_count, with_exclusions: with_exclusions) }
      cache.fetch_multi(*items, force: force_cache?) { |entry|
        AssignedPatientsQuery.new.count(entry.region, :month, with_exclusions: with_exclusions)
      }
    end

    def cumulative_assigned_patients_count
      full_assigned_patients_counts.each_with_object({}) do |(region_entry, patient_counts), totals|
        region_slug = region_entry.region.slug
        totals[region_slug] = Hash.new(0)
        next if patient_counts.empty?
        first_period = patient_counts.keys.first
        full_range = (first_period..periods.end)
        full_range.each do |period|
          previous_total = totals[region_slug][period.previous]
          current_amount = patient_counts[period] || 0
          totals[region_slug][period] += previous_total + current_amount
        end
      end
    end

    def controlled_patients_count
      cached_query(:controlled_patients_count) do |entry|
        control_rate_query.controlled(entry.region, entry.period, with_exclusions: with_exclusions).count
      end
    end

    def uncontrolled_patients_count
      cached_query(:uncontrolled_patients_count) do |entry|
        control_rate_query.uncontrolled(entry.region, entry.period, with_exclusions: with_exclusions).count
      end
    end

    def controlled_patient_rates
      cached_query(:controlled_patient_rates) do |entry|
        controlled = controlled_patients_count[entry.region.slug][entry.period]
        total = cumulative_assigned_patients_count[entry.region.slug][entry.period]
        percentage(controlled, total)
      end
    end

    def uncontrolled_patient_rates
      cached_query(:uncontrolled_patient_rates) do |entry|
        controlled = uncontrolled_patients_count[entry.region.slug][entry.period]
        total = cumulative_assigned_patients_count[entry.region.slug][entry.period]
        percentage(controlled, total)
      end
    end

    def missed_visits_count
      cached_query(:missed_visits_count) do |entry|
        no_bp_measure_query.call(entry.region, entry.period, with_exclusions: with_exclusions)
      end
    end

    def missed_visits_rate
      cached_query(:missed_visits_rate) do |entry|
        controlled = missed_visits_count[entry.region.slug][entry.period]
        total = cumulative_assigned_patients_count[entry.region.slug][entry.period]
        percentage(controlled, total)
      end
    end

    private

    # Generate all necessary cache keys for a calculation, then yield to the block with every entry.
    # Once all results are returned via fetch_multi, return the data in a standard format of:
    #   {
    #     region_1_slug: { period_1: value, period_2: value }
    #     region_2_slug: { period_1: value, period_2: value }
    #   }
    #
    def cached_query(calculation, &block)
      items = cache_entries(calculation)
      cached_results = cache.fetch_multi(*items, force: force_cache?) { |entry|
        block.call(entry)
      }
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

    def no_bp_measure_query
      @no_bp_measure_query ||= NoBPMeasureQuery.new
    end

    def control_rate_query
      @control_rate_query ||= ControlRateQuery.new
    end

    def force_cache?
      RequestStore.store[:force_cache]
    end
  end
end
