require_relative "experiment"
module Reports
  class Repository
    include BustCache
    include Memery
    include Scientist

    attr_reader :bp_measures_query
    attr_reader :follow_ups_query
    attr_reader :period_type
    attr_reader :periods
    attr_reader :regions
    attr_reader :registered_patients_query
    attr_reader :schema

    def initialize(regions, periods:, follow_ups_v2: Flipper.enabled?(:follow_ups_v2))
      @regions = Array(regions).map(&:region)
      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods
      end
      @period_type = @periods.first.type
      @follow_ups_v2 = follow_ups_v2
      raise ArgumentError, "Quarter periods not supported" if @period_type != :month
      @schema = SchemaV2.new(@regions, periods: @periods)
      @bp_measures_query = BPMeasuresQuery.new
      @follow_ups_query = FollowUpsQuery.new
      @registered_patients_query = RegisteredPatientsQuery.new
      @overdue_calls_query = OverdueCallsQuery.new
    end

    delegate :cache, :logger, to: Rails

    DELEGATED_RATES = %i[
      controlled_rates
      ltfu_rates
      missed_visits_rate
      missed_visits_with_ltfu_rates
      missed_visits_without_ltfu_rates
      uncontrolled_rates
      visited_without_bp_taken_rates
      appts_scheduled_0_to_14_days_rates
      appts_scheduled_15_to_31_days_rates
      appts_scheduled_32_to_62_days_rates
      appts_scheduled_more_than_62_days_rates
    ]

    DELEGATED_COUNTS = %i[
      adjusted_patients_with_ltfu
      adjusted_patients_without_ltfu
      assigned_patients
      complete_monthly_registrations
      controlled
      cumulative_assigned_patients
      cumulative_registrations
      earliest_patient_recorded_at
      earliest_patient_recorded_at_period
      under_care
      ltfu
      missed_visits
      missed_visits_with_ltfu
      missed_visits_without_ltfu
      monthly_registrations
      uncontrolled
      visited_without_bp_taken
      monthly_overdue_calls
      total_appts_scheduled
      appts_scheduled_0_to_14_days
      appts_scheduled_15_to_31_days
      appts_scheduled_32_to_62_days
      appts_scheduled_more_than_62_days
    ]

    def warm_cache
      DELEGATED_RATES.each do |method|
        public_send(method)
        public_send(method, with_ltfu: true) unless method.in?([:ltfu_rates, :missed_visits_with_ltfu_rates])
      end
      hypertension_follow_ups
      if regions.all? { |region| region.facility_region? }
        hypertension_follow_ups(group_by: "blood_pressures.user_id")
        bp_measures_by_user
        monthly_registrations_by_user
      end
    end

    delegate(*DELEGATED_COUNTS, to: :schema)
    delegate(*DELEGATED_RATES, to: :schema)

    alias_method :adjusted_patients, :adjusted_patients_without_ltfu

    # Returns registration counts per region / period counted by registration_user
    memoize def monthly_registrations_by_user
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :registration_user_id, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        registered_patients_query.count(entry.region, period_type, group_by: :registration_user_id)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    # Returns Follow ups per Region / Period. Takes an optional group_by clause (commonly used to group by user_id)
    memoize def hypertension_follow_ups(group_by: nil)
      if follow_ups_v2?
        schema.hypertension_follow_ups(group_by: group_by)
      else
        follow_ups_v1(group_by: group_by)
      end
    end

    memoize def follow_ups_v1(group_by: nil)
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: group_by, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        follow_ups_query.hypertension(entry.region, period_type, group_by: group_by)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    def follow_ups_v2?
      @follow_ups_v2
    end

    memoize def bp_measures_by_user
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :user_id, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        bp_measures_query.count(entry.region, period_type, group_by: :user_id)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    memoize def overdue_calls_by_user
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :user_id, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        @overdue_calls_query.count(entry.region, period_type, group_by: :user_id)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    def period_info(region)
      start_period = [earliest_patient_recorded_at_period[region.slug], periods.begin].compact.max
      calc_range = (start_period..periods.end)
      calc_range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }
    end
  end
end
