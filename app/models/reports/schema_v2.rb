module Reports
  class SchemaV2
    include BustCache
    include Memery

    attr_reader :control_rate_query_v2
    attr_reader :periods
    attr_reader :period_hash
    attr_reader :period_type
    attr_reader :regions

    delegate :cache, :logger, to: Rails

    def initialize(regions, periods:)
      @regions = regions
      @periods = periods
      @period_type = @periods.first.type
      @control_rate_query_v2 = ControlRateQueryV2.new
      @period_hash = lambda { |month_date, count| [Period.month(month_date), count] }
    end

    # Returns the earliest patient record for a Region from either assigned or registered patients. Note that this *ignores*
    # the periods that are passed in for the Repository - this is the true 'earliest report date' for a Region.
    memoize def earliest_patient_recorded_at
      region_entries = regions.map { |region| RegionEntry.new(region, __method__) }
      cached_results = cache.fetch_multi(*region_entries, force: bust_cache?) { |region_entry|
        earliest_patient_data_query_v2(region_entry.region)
      }
      cached_results.each_with_object({}) { |(region_entry, time), results| results[region_entry.slug] = time }
    end

    memoize def earliest_patient_recorded_at_period
      earliest_patient_recorded_at.each_with_object({}) { |(slug, time), hsh| hsh[slug] = Period.new(value: time, type: @period_type) if time }
    end

    private def earliest_patient_data_query_v2(region)
      FacilityState.for_region(region).where("cumulative_registrations > 0 OR cumulative_assigned_patients > 0")
        .minimum(:month_date)
    end

    # Adjusted patient counts are the patient counts from three months ago (the adjusted period) that
    # are the basis for control rates. These counts DO include lost to follow up.
    memoize def adjusted_patients_with_ltfu
      cumulative_assigned_patients.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          region_result[period] = result[period.adjusted_period]
        }
        results[entry] = values
      end
    end

    # Adjusted patient counts are the patient counts from three months ago (the adjusted period) that
    # are the basis for control rates. These counts DO NOT include lost to follow up.
    memoize def adjusted_patients_without_ltfu
      regions.each_with_object({}) { |region, result|
        result[region.slug] = adjusted_patients_without_ltfu_query(region).slice(*periods.entries)
      }
    end

    private def adjusted_patients_without_ltfu_query(region)
      FacilityState.for_region(region)
        .order(:month_date)
        .group(:month_date)
        .sum("patients_under_care::int")
        .to_h(&period_hash)
        .tap { |hsh| hsh.default = 0 }
    end

    alias_method :adjusted_patients, :adjusted_patients_without_ltfu

    # Return the running total of cumulative assigned patient counts. Note that this *includes* LTFU.
    memoize def cumulative_assigned_patients
      regions.each_with_object({}) { |region, result|
        result[region.slug] = cumulative_assigned_patients_query_v2(region)
      }
    end

    # Returns cumulative assigned patients from facility_states - this includes LTFU
    private def cumulative_assigned_patients_query_v2(region)
      FacilityState.for_region(region)
        .order(:month_date)
        .group(:month_date)
        .sum("cumulative_assigned_patients::int")
        .to_h(&period_hash)
        .tap { |hsh| hsh.default = 0 }
    end

    # Returns registration counts per region / period
    memoize def monthly_registrations
      regions.each_with_object({}) { |region, result|
        result[region.slug] = registered_patients_query_v2(region).slice(*periods.entries)
      }
    end

    def registered_patients_query_v2(region)
      return {} if earliest_patient_recorded_at_period[region.slug].nil?
      FacilityState.for_region(region)
        .where("month_date >= ?", earliest_patient_recorded_at_period[region.slug].to_date)
        .order(:month_date)
        .group(:month_date)
        .sum("monthly_registrations::int")
        .to_h(&period_hash)
        .tap { |hsh| hsh.default = 0 }
    end

    memoize def cumulative_registrations
      regions.each_with_object({}) { |region, result|
        result[region.slug] = cumulative_registered_patients_query_v2(region).slice(*periods.entries)
      }
    end

    private def cumulative_registered_patients_query_v2(region)
      return {} if earliest_patient_recorded_at_period[region.slug].nil?
      FacilityState.for_region(region)
        .where("month_date >= ?", earliest_patient_recorded_at_period[region.slug].to_date)
        .order(:month_date)
        .group(:month_date)
        .sum("cumulative_registrations::int")
        .to_h(&period_hash)
        .tap { |hsh| hsh.default = 0 }
    end

    memoize def ltfu
      regions.each_with_object({}) { |region, hsh| hsh[region.slug] = ltfu_query_v2(region) }
    end

    private def ltfu_query_v2(region)
      FacilityState.for_region(region)
        .order(:month_date)
        .group(:month_date)
        .sum("lost_to_follow_up::int")
        .to_h(&period_hash)
        .tap { |hsh| hsh.default = 0 }
    end

    memoize def ltfu_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(ltfu[slug][period], cumulative_assigned_patients[slug][period])
      end
    end

    memoize def controlled
      regions.each_with_object({}).each do |region, hsh|
        if earliest_patient_recorded_at[region.slug].nil?
          hsh[region.slug] = Hash.new(0)
          next
        end
        hsh[region.slug] = control_rate_query_v2.controlled_counts(region, range: active_range(region))
      end
    end

    memoize def uncontrolled
      regions.each_with_object({}).each do |region, hsh|
        if earliest_patient_recorded_at[region.slug].nil?
          hsh[region.slug] = Hash.new(0)
          next
        end
        hsh[region.slug] = control_rate_query_v2.uncontrolled_counts(region, range: active_range(region))
      end
    end

    memoize def controlled_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        numerator = controlled[entry.slug][entry.period]
        total = denominator(entry.region, entry.period, with_ltfu: with_ltfu)
        percentage(numerator, total)
      end
    end

    memoize def uncontrolled_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        numerator = uncontrolled[entry.region.slug][entry.period]
        total = denominator(entry.region, entry.period, with_ltfu: with_ltfu)
        percentage(numerator, total)
      end
    end

    private

    # Return the actual 'active range' for a Region - this will be the from the first recorded at in a region until
    # the end of the period range requested.
    def active_range(region)
      start = [earliest_patient_recorded_at_period[region.slug], periods.begin].compact.max
      (start..periods.end)
    end

    def denominator(region, period, with_ltfu: false)
      if with_ltfu
        adjusted_patients_without_ltfu[region.slug][period] + ltfu[region.slug][period]
      else
        adjusted_patients_without_ltfu[region.slug][period]
      end
    end

    # Generate all necessary cache keys for a calculation, then yield to the block for every entry.
    # Once all results are returned via fetch_multi, return the data in a standard format of:
    #   {
    #     region_1_slug: { period_1: value, period_2: value }
    #     region_2_slug: { period_1: value, period_2: value }
    #   }
    #
    def region_period_cached_query(calculation, **options, &block)
      results = regions.each_with_object({}) { |region, hsh| hsh[region.slug] = Hash.new(0) }
      items = cache_entries(calculation, **options)
      cached_results = cache.fetch_multi(*items, force: bust_cache?) { |entry| block.call(entry) }
      cached_results.each { |(entry, count)| results[entry.region.slug][entry.period] = count }
      results
    end

    # Generate all necessary region period cache entries, only going back to the earliest
    # patient registration date for Periods. This ensures that we don't create many cache entries
    # with 0 data for newer Regions.
    def cache_entries(calculation, **options)
      combinations = regions.each_with_object([]) do |region, results|
        earliest_period = earliest_patient_recorded_at_period[region.slug]
        next if earliest_period.nil?
        periods_with_data = periods.select { |period| period >= earliest_period }
        results.concat(periods_with_data.to_a.map { |period| [region, period] })
      end
      options[:class] = self.class
      combinations.map { |region, period| Reports::RegionPeriodEntry.new(region, period, calculation, options) }
    end

    def percentage(numerator, denominator)
      return 0 if numerator.nil? || denominator.nil? || denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
    end
  end
end
