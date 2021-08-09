module Reports
  class SchemaV2
    include BustCache
    include Memery

    FIELDS = %i[
      controlled_under_care
      cumulative_assigned_patients
      cumulative_registrations
      lost_to_follow_up
      missed_visit_lost_to_follow_up
      missed_visit_under_care
      monthly_registrations
      patients_under_care
      uncontrolled_under_care
      visited_no_bp_under_care
      visited_no_bp_lost_to_follow_up
    ].freeze

    attr_reader :control_rate_query_v2
    attr_reader :periods
    attr_reader :period_hash
    attr_reader :regions

    delegate :cache, :logger, to: Rails

    def initialize(regions, periods:)
      @regions = regions
      @periods = periods
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
      earliest_patient_recorded_at.each_with_object({}) { |(slug, time), hsh| hsh[slug] = Period.new(value: time, type: :month) if time }
    end

    private def earliest_patient_data_query_v2(region)
      FacilityState.for_region(region)
        .where("cumulative_registrations > 0 OR cumulative_assigned_patients > 0")
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
      regions.each_with_object({}) { |region, result| result[region.slug] = sum(region, :patients_under_care) }
    end

    alias_method :adjusted_patients, :adjusted_patients_without_ltfu

    # Return the running total of cumulative assigned patient counts. Note that this *includes* LTFU.
    memoize def cumulative_assigned_patients
      regions.each_with_object({}) { |region, result| result[region.slug] = sum(region, :cumulative_assigned_patients) }
    end

    # Returns registration counts per region / period
    memoize def monthly_registrations
      regions.each_with_object({}) { |region, result| result[region.slug] = sum(region, :monthly_registrations) }
    end

    memoize def cumulative_registrations
      regions.each_with_object({}) { |region, result| result[region.slug] = sum(region, :cumulative_registrations) }
    end

    memoize def ltfu
      regions.each_with_object({}) { |region, hsh| hsh[region.slug] = sum(region, :lost_to_follow_up) }
    end

    memoize def ltfu_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(ltfu[slug][period], cumulative_assigned_patients[slug][period])
      end
    end

    memoize def controlled
      regions.each_with_object({}) { |region, hsh| hsh[region.slug] = sum(region, :controlled_under_care) }
    end

    memoize def uncontrolled
      regions.each_with_object({}) { |region, hsh| hsh[region.slug] = sum(region, :uncontrolled_under_care) }
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

    memoize def missed_visits(with_ltfu: false)
      field = with_ltfu ? :missed_visit_lost_to_follow_up : :missed_visit_under_care
      regions.each_with_object({}) { |region, hsh| hsh[region.slug] = sum(region, field) }
    end

    def missed_visits_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        slug, period = entry.slug, entry.period
        numerator = missed_visits(with_ltfu: with_ltfu)[slug][period]
        total = denominator(entry.region, period, with_ltfu: with_ltfu)
        percentage(numerator, total)
      end
    end

    alias_method :missed_visits_without_ltfu, :missed_visits
    alias_method :missed_visits_without_ltfu_rates, :missed_visits_rates

    def missed_visits_with_ltfu
      missed_visits(with_ltfu: true)
    end

    def missed_visits_with_ltfu_rates
      missed_visits_rates(with_ltfu: true)
    end

    private

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

    # Grab a particular summed field for a region. We return data in the format of:
    #   { region_slug => { period_1 => x, period_2 => y }, ...}
    # to maintain consistency w/ the format callers expect from the Repository.
    #
    # Note that we do filtering on the result set to limit the returned amount of data to the data that callers are
    # requesting via the `periods` argument the Repository was created with.
    def sum(region, field)
      summed_field = "sum_#{field}"
      facility_state_data(region)
        .reject { |facility_state| Period.month(facility_state.month_date) < earliest_patient_recorded_at_period[region.slug] }
        .select { |facility_state| facility_state.period_month_date.in?(periods) }
        .to_h { |facility_state| [Period.month(facility_state.month_date), facility_state.public_send(summed_field)] }
        .tap { |hsh| hsh.default = 0 }
    end

    delegate :sql, to: Arel

    # Grab all the summed data for a particular region grouped by month_date.
    # We need to use COALESCE to avoid getting nil back from some of the values, and we need to use
    # `select` because the `sum` methods in ActiveRecord can't sum multiple fields.
    # We also order by `month_date` because some code in the views expects elements to be ordered by Period from
    # oldest to newest - it also makes reading output in specs and debugging much easier.
    memoize def facility_state_data(region)
      calculations = FIELDS.map { |field| Arel.sql("COALESCE(SUM(#{field}::int), 0) as sum_#{field}") }

      FacilityState.for_region(region)
        .where("cumulative_registrations IS NOT NULL OR cumulative_assigned_patients IS NOT NULL")
        .order(:month_date)
        .group(:month_date)
        .select(:month_date)
        .select(*calculations)
    end
  end
end
