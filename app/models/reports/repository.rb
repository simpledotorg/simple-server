module Reports
  class Repository
    include BustCache
    include Memery
    PERCENTAGE_PRECISION = 0

    def initialize(regions, periods:)
      @regions = Array(regions)
      @no_bp_measure_query = NoBPMeasureQuery.new
      @control_rate_query = ControlRateQuery.new
      @earliest_patient_data_query = EarliestPatientDataQuery.new

      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods
      end
      @period_type = @periods.first.type
      raise ArgumentError, "Quarter periods not supported" if @period_type != :month
    end

    attr_reader :control_rate_query
    attr_reader :earliest_patient_data_query
    attr_reader :no_bp_measure_query
    attr_reader :period_type
    attr_reader :periods
    attr_reader :regions

    delegate :cache, :logger, to: Rails

    # Returns the earliest patient record for a Region from either assigned or registered patients. Note that this *ignores*
    # the periods that are passed in for the Repository - this is the true 'earliest report date' for a Region.
    memoize def earliest_patient_recorded_at
      region_entries = regions.map { |region| RegionEntry.new(region, __method__) }
      cached_results = cache.fetch_multi(*region_entries, force: bust_cache?) { |region_entry|
        earliest_patient_data_query.call(region_entry.region)
      }
      cached_results.each_with_object({}) { |(region_entry, time), results| results[region_entry.slug] = time }
    end

    memoize def earliest_patient_recorded_at_period
      earliest_patient_recorded_at.each_with_object({}) { |(slug, time), hsh| hsh[slug] = Period.new(value: time, type: @period_type) if time }
    end

    # Returns assigned patients for a Region. NOTE: We grab and cache ALL the counts for a particular region with one SQL query
    # because it is easier and fast enough to do so. We still return _just_ the periods the Repository was created with
    # to conform to the same interface as all the other queries here.

    # Returns a Hash in the shape of:
    # {
    #    region_slug: { period: value, period: value },
    #    region_slug: { period: value, period: value }
    # }
    memoize def assigned_patients_count
      complete_assigned_patients_counts.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result| region_result[period] = result[period] if result[period] }
        results[entry.region.slug] = values
      end
    end

    memoize def adjusted_patient_counts_with_ltfu
      cumulative_assigned_patients_count.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          region_result[period] = result[period.adjusted_period]
        }
        results[entry] = values
      end
    end

    memoize def adjusted_patient_counts
      cumulative_assigned_patients_count.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          region_result[period] = result[period.adjusted_period] - ltfu_counts[entry][period]
        }
        results[entry] = values
      end
    end

    alias_method :adjusted_patient_counts_without_ltfu, :adjusted_patient_counts

    # Returns the full range of assigned patient counts for a Region. We do this via one SQL query for each Region, because its
    # fast and easy via the underlying query.
    memoize def complete_assigned_patients_counts
      items = regions.map { |region| RegionEntry.new(region, __method__, period_type: period_type) }
      cache.fetch_multi(*items, force: bust_cache?) { |region_entry|
        AssignedPatientsQuery.new.count(region_entry.region, period_type)
      }
    end

    # Return the running total of cumulative assigned patient counts.
    memoize def cumulative_assigned_patients_count
      complete_assigned_patients_counts.each_with_object({}) do |(region_entry, patient_counts), totals|
        slug = region_entry.slug
        next totals[slug] = Hash.new(0) if earliest_patient_recorded_at[slug].nil?
        range = Range.new(earliest_patient_recorded_at_period[slug], periods.end)
        totals[slug] = range.each_with_object(Hash.new(0)) { |period, sum|
          sum[period] = sum[period.previous] + patient_counts.fetch(period, 0)
        }
      end
    end

    memoize def registration_counts
      complete_registration_counts.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result| region_result[period] = result[period] if result[period] }
        results[entry.region.slug] = values
      end
    end

    # Returns the full range of registered patient counts for a Region. We do this via one SQL query for each Region, because its
    # fast and easy via the underlying query.
    memoize def complete_registration_counts
      items = regions.map { |region| RegionEntry.new(region, __method__, period_type: period_type) }
      cache.fetch_multi(*items, force: bust_cache?) { |entry|
        RegisteredPatientsQuery.new.count(entry.region, period_type)
      }
    end

    memoize def cumulative_registrations
      complete_registration_counts.each_with_object({}) do |(region_entry, patient_counts), totals|
        range = Range.new(patient_counts.keys.first || periods.first, periods.end)
        totals[region_entry.slug] = range.each_with_object(Hash.new(0)) { |period, sum|
          sum[period] = sum[period.previous] + patient_counts.fetch(period, 0)
        }
      end
    end

    memoize def ltfu_counts
      cached_query(__method__) do |entry|
        facility_ids = entry.region.facility_ids
        Patient.for_reports.where(assigned_facility: facility_ids).ltfu_as_of(entry.period.end).count
      end
    end

    memoize def controlled_patients_count
      cached_query(__method__) do |entry|
        control_rate_query.controlled(entry.region, entry.period).count
      end
    end

    memoize def uncontrolled_patients_count
      cached_query(__method__) do |entry|
        control_rate_query.uncontrolled(entry.region, entry.period).count
      end
    end

    memoize def missed_visits
      cached_query(__method__) do |entry|
        slug = entry.slug
        patient_count = denominator(entry.region, entry.period)
        controlled = controlled_patients_count[slug][entry.period]
        uncontrolled = uncontrolled_patients_count[slug][entry.period]
        visits = visited_without_bp_taken[slug][entry.period]
        patient_count - visits - controlled - uncontrolled
      end
    end

    memoize def missed_visits_rate
      cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        remaining_percentages = controlled_patients_rate[slug][period] + uncontrolled_patients_rate[slug][period] + visited_without_bp_taken_rate[slug][period]
        100 - remaining_percentages
      end
    end

    # This method currently always returns the "excluding LTFU denominator".
    # Repository only returns "excluding LTFU" rates.
    # This only powers queries for children regions which do not require both variants of control rates, unlike Result.
    # As we deprecate Result and shift to Repository, a Repository object should be able to return both rates.
    def denominator(region, period)
      cumulative_assigned_patients_count[region.slug][period.adjusted_period] - ltfu_counts[region.slug][period]
    end

    memoize def controlled_patients_rate
      cached_query(__method__) do |entry|
        controlled = controlled_patients_count[entry.region.slug][entry.period]
        total = denominator(entry.region, entry.period)
        percentage(controlled, total)
      end
    end

    memoize def uncontrolled_patients_rate
      cached_query(__method__) do |entry|
        controlled = uncontrolled_patients_count[entry.region.slug][entry.period]
        total = denominator(entry.region, entry.period)
        percentage(controlled, total)
      end
    end

    memoize def visited_without_bp_taken
      cached_query(__method__) do |entry|
        no_bp_measure_query.call(entry.region, entry.period)
      end
    end

    memoize def visited_without_bp_taken_rate
      cached_query(__method__) do |entry|
        controlled = visited_without_bp_taken[entry.region.slug][entry.period]
        total = denominator(entry.region, entry.period)
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
      cached_results = cache.fetch_multi(*items, force: bust_cache?) { |entry| block.call(entry) }
      cached_results.each_with_object({}) do |(entry, count), results|
        results[entry.region.slug] ||= Hash.new(0)
        next if earliest_patient_recorded_at_period[entry.slug].nil?
        next if entry.period < earliest_patient_recorded_at_period[entry.slug]
        results[entry.region.slug][entry.period] = count
      end
    end

    def cache_entries(calculation)
      combinations = regions.to_a.product(periods.to_a)
      combinations.map { |region, period| Reports::RegionPeriodEntry.new(region, period, calculation) }
    end

    def percentage(numerator, denominator)
      return 0 if denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end
  end
end
