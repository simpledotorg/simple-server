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

    class CacheKey
      def initialize(key)
        @key = key
        @parts = key.split("/")
      end

      def region_id
        @parts[1]
      end

      def slug
        @parts[2]
      end

      def period
        Period.new(type: @parts[3], value: @parts[4])
      end
    end

    def lookup_region(id)
      @regions_by_id.fetch(id)
    end

    def controlled_patients_info
      keys = cache_keys(:controlled_patients_info)
      cached_results = cache.fetch_multi(*keys) { |key|
        cache_key = CacheKey.new(key)
        period = cache_key.period
        region = lookup_region(cache_key.region_id)
        controlled_patients_for(region, period).count
      }
      results = {}
      cached_results.each do |key, result|
        cache_key = CacheKey.new(key)
        results[cache_key.slug] ||= {}
        results[cache_key.slug][cache_key.period] = result
      end
      results
    end

    def uncontrolled_patients_info
      keys = cache_keys(:uncontrolled_patients_info)
      cached_results = cache.fetch_multi(*keys) { |key|
        cache_key = CacheKey.new(key)
        period = cache_key.period
        region = lookup_region(cache_key.region_id)
        uncontrolled_patients_for(region, period).count
      }
      results = {}
      cached_results.each do |key, result|
        cache_key = CacheKey.new(key)
        results[cache_key.slug] ||= {}
        results[cache_key.slug][cache_key.period] = result
      end
      results
    end

    def cache_keys(operation)
      combinations = regions.to_a.map(&:cache_key_v2).product(periods.map(&:cache_key))
      combinations.map { |region_key, period_key| [region_key, period_key, operation].join("/") }
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
