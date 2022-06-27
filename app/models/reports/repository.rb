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
    alias_method :range, :periods

    def initialize(regions, periods:)
      @regions = Array(regions).map(&:region)
      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods
      end
      @period_type = @periods.first.type
      raise ArgumentError, "Quarter periods not supported" if @period_type != :month
      @schema = RegionSummarySchema.new(@regions, periods: @periods)
      @bp_measures_query = BPMeasuresQuery.new
      @follow_ups_query = FollowUpsQuery.new
      @registered_patients_query = RegisteredPatientsQuery.new
      @overdue_calls_query = OverdueCallsQuery.new
    end

    delegate :cache, :logger, to: Rails

    DELEGATED_RATES = %i[
      controlled_rates
      ltfu_rates
      diabetes_ltfu_rates
      missed_visits_rate
      missed_visits_with_ltfu_rates
      missed_visits_without_ltfu_rates
      uncontrolled_rates
      visited_without_bp_taken_rates
      appts_scheduled_0_to_14_days_rates
      appts_scheduled_15_to_31_days_rates
      appts_scheduled_32_to_62_days_rates
      appts_scheduled_more_than_62_days_rates
      bs_below_200_rates
      bs_200_to_300_rates
      bs_over_300_rates
      diabetes_missed_visits_rates
      visited_without_bs_taken_rates
      diabetes_appts_scheduled_0_to_14_days_rates
      diabetes_appts_scheduled_15_to_31_days_rates
      diabetes_appts_scheduled_32_to_62_days_rates
      diabetes_appts_scheduled_more_than_62_days_rates
    ]

    DELEGATED_COUNTS = %i[
      adjusted_patients_with_ltfu
      adjusted_patients_without_ltfu
      assigned_patients
      complete_monthly_registrations
      controlled
      cumulative_assigned_patients
      cumulative_registrations
      cumulative_assigned_diabetic_patients
      cumulative_diabetes_registrations
      earliest_patient_recorded_at
      earliest_patient_recorded_at_period
      under_care
      ltfu
      diabetes_ltfu
      missed_visits
      missed_visits_with_ltfu
      missed_visits_without_ltfu
      monthly_registrations
      monthly_diabetes_registrations
      uncontrolled
      visited_without_bp_taken
      monthly_overdue_calls
      monthly_diabetes_followups
      total_appts_scheduled
      appts_scheduled_0_to_14_days
      appts_scheduled_15_to_31_days
      appts_scheduled_32_to_62_days
      appts_scheduled_more_than_62_days
      adjusted_diabetes_patients_without_ltfu
      adjusted_diabetes_patients_with_ltfu
      adjusted_diabetes_patients
      bs_below_200_patients
      bs_200_to_300_patients
      bs_over_300_patients
      diabetes_missed_visits
      visited_without_bs_taken
      diabetes_patients_with_bs_taken
      diabetes_total_appts_scheduled
      diabetes_appts_scheduled_0_to_14_days
      diabetes_appts_scheduled_15_to_31_days
      diabetes_appts_scheduled_32_to_62_days
      diabetes_appts_scheduled_more_than_62_days
    ]

    DELEGATED_BREAKDOWNS = %i[
      diabetes_treatment_outcome_breakdown_rates
      diabetes_treatment_outcome_breakdown_counts
      diabetes_patients_with_bs_taken_breakdown_rates
      diabetes_patients_with_bs_taken_breakdown_counts
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
        monthly_registrations_by_gender
        controlled_by_gender
        overdue_calls_by_user
      end
    end

    delegate(*DELEGATED_COUNTS, to: :schema)
    delegate(*DELEGATED_RATES, to: :schema)
    delegate(*DELEGATED_BREAKDOWNS, to: :schema)

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

    # Returns registration counts per region / period counted by gender
    memoize def monthly_registrations_by_gender
      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :gender, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        registered_patients_query.count(entry.region, period_type, group_by: :gender)
      end
      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    # Controlled patients by gender for Maharashtra DHIS2 integration pilot. Until gender disaggregation has first-class
    # support in the reporting pipeline, this method is a very one-off workaround to add the necessary numbers to the
    # repository. We choose to add this method to the repository so that the DHIS2 exporter can work off of a consistent
    # interface.
    #
    # Since its use-case is tightly constrained, we introduce several hard checks to ensure that only monthly reports
    # for facilities are requested.
    memoize def controlled_by_gender
      raise "Controlled patients by gender is only available for facilities." unless regions.all? { |region| region.region_type == "facility" }
      raise "Controlled patients by gender is only available for monthly reports" unless period_type == :month

      items = regions.map { |region| RegionEntry.new(region, __method__, group_by: :gender, period_type: period_type) }
      result = cache.fetch_multi(*items, force: bust_cache?) do |entry|
        # Recreate the controlled patients indicator based on the implementatino of reporting_facility_states
        facility_counts = Reports::PatientState
          .where(
            assigned_facility_region_id: entry.region.id,
            htn_care_state: "under_care",
            htn_treatment_outcome_in_last_3_months: "controlled",
            hypertension: "yes"
          )
          .where("months_since_registration >= 3")
          .group_by_period(period_type, :month_date, {format: Period.formatter(period_type)})
          .group(:gender)
          .count

        # Group the results into { period: {male: 123, female: 456} }
        facility_counts.each_with_object({}) { |(key, count), hsh|
          period, field_id = *key
          hsh[period] ||= {}
          hsh[period][field_id] = count
        }
      end

      result.each_with_object({}) { |(region_entry, counts), hsh|
        hsh[region_entry.region.slug] = counts
      }
    end

    # Returns Follow ups per Region / Period. Takes an optional group_by clause (commonly used to group by user_id)
    memoize def hypertension_follow_ups(group_by: nil)
      schema.hypertension_follow_ups(group_by: group_by)
    end

    memoize def diabetes_follow_ups(group_by: nil)
      schema.diabetes_follow_ups(group_by: group_by)
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

    # Returns facility progress dimensional data (for progress tab) in the form of
    #   region => { period_1 => monthly_facility_progress_record, period_2 => monthly_facility_progress_1 }
    # Note that this does differ from the more standard return values returned from the Repository because
    # this data is specifically for the Progress Tab, where all the dimensions are needed at once
    def facility_progress
      regions.each_with_object({}) do |region, result|
        records = Reports::FacilityStateDimension.for_region(region).where(month_date: periods)
        records_per_period = records.each_with_object({}) do |record, hsh|
          hsh[record.period] = record
        end
        result[region.slug] = records_per_period
      end
    end

    def period_info(region)
      start_period = [earliest_patient_recorded_at_period[region.slug], periods.begin].compact.max
      calc_range = (start_period..periods.end)
      calc_range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }
    end
  end
end
