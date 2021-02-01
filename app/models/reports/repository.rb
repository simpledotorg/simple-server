module Reports
  class Repository
    def initialize(regions, periods:)
      @regions = Array(regions)
      @regions_by_id = @regions.map { |r| [r.id, r] }.to_h

      @periods = if periods.is_a?(Period)
        Range.new(periods, periods).to_a
      else
        periods.to_a
      end
    end

    attr_reader :regions, :periods
    attr_reader :regions_by_id
    delegate :cache, :logger, to: Rails
    class Item
      attr_reader :region, :period, :calculation
      def initialize(region, period, calculation)
        @region = region
        @period = period
        @calculation = calculation
      end

      def cache_key
        [region.cache_key_v2, period.cache_key, calculation].join("/")
      end
    end

    def controlled_patients_info
      items = cache_keys(:controlled_patients_info)
      cached_results = cache.fetch_multi(*items) { |item|
        controlled_patients_for(item.region, item.period).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def uncontrolled_patients_info
      items = cache_keys(:uncontrolled_patients_info)
      cached_results = cache.fetch_multi(*items) { |item|
        uncontrolled_patients_for(item.region, item.period).count
      }
      cached_results.each_with_object({}) do |(item, count), results|
        results[item.region.slug] ||= Hash.new(0)
        results[item.region.slug][item.period] = count
      end
    end

    def cache_keys(calculation)
      combinations = regions.to_a.product(periods)
      combinations.map { |region, period| Item.new(region, period, calculation) }
    end

    def controlled_patients_for(region, period)
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_monthly_query(region, period),
        "latest_blood_pressures_per_patient_per_months").under_control
    end

    def uncontrolled_patients_for(region, period)
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_monthly_query(region, period),
        "latest_blood_pressures_per_patient_per_months").hypertensive
    end

    def bp_monthly_query(region, period)
      control_range = period.blood_pressure_control_range
      # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
      # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
      LatestBloodPressuresPerPatientPerMonth
        .with_discarded
        .for_reports(with_exclusions: false)
        .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
        .where(assigned_facility_id: region.facilities)
        .where("patient_recorded_at < ?", control_range.begin) # TODO this doesn't seem right -- revisit this exclusion
        .where("bp_recorded_at > ? and bp_recorded_at <= ?", control_range.begin, control_range.end)
        .order("latest_blood_pressures_per_patient_per_months.patient_id, bp_recorded_at DESC, bp_id")
    end
  end
end
