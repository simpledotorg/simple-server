module Reports
  class RegionService
    # The default period we report on is the current month.
    def self.default_period
      Period.month(Time.current.in_time_zone(Period::REPORTING_TIME_ZONE))
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(region:, period:, months: MAX_MONTHS_OF_DATA, reporting_schema_v2: false)
      @region = region
      @slug = @region.slug
      @period = period
      @reporting_schema_v2 = reporting_schema_v2
      start_period = period.advance(months: -(months - 1))
      @range = Range.new(start_period, @period)
      #--------------------------------- debugger
    end

    attr_reader :result
    attr_reader :period
    attr_reader :range
    attr_reader :region
    attr_reader :slug

    def call
      result = Reports::Result.new(region: @region, period_type: @range.begin.type)
      result.earliest_registration_period = repository.earliest_patient_recorded_at_period[slug]
      result.adjusted_patient_counts = repository.adjusted_patients_without_ltfu[slug]
      result.adjusted_patient_counts_with_ltfu = repository.adjusted_patients_with_ltfu[slug]
      result.controlled_patients = repository.controlled[slug]
      result.controlled_patients_rate = repository.controlled_rates[slug]
      result.controlled_patients_with_ltfu_rate = repository.controlled_rates(with_ltfu: true)[slug]
      result.cumulative_assigned_patients = repository.cumulative_assigned_patients[slug]
      result.cumulative_registrations = repository.cumulative_registrations[slug]
      result.ltfu_patients = repository.ltfu[slug]
      result.ltfu_patients_rate = repository.ltfu_rates[slug]
      result.registrations = repository.monthly_registrations[slug]
      result.uncontrolled_patients = repository.uncontrolled[slug]
      result.uncontrolled_patients_rate = repository.uncontrolled_rates[slug]
      result.uncontrolled_patients_with_ltfu_rate = repository.uncontrolled_rates(with_ltfu: true)[slug]

      result.visited_without_bp_taken = repository.visited_without_bp_taken[region.slug]
      result.visited_without_bp_taken_rates = repository.visited_without_bp_taken_rates[region.slug]
      result.visited_without_bp_taken_with_ltfu_rates = repository.visited_without_bp_taken_rates(with_ltfu: true)[region.slug]

      result.missed_visits = repository.missed_visits[region.slug]
      result.missed_visits_rate = repository.missed_visits_without_ltfu_rates[region.slug]
      result.missed_visits_with_ltfu = repository.missed_visits_with_ltfu[region.slug]
      result.missed_visits_with_ltfu_rate = repository.missed_visits_with_ltfu_rates[region.slug]

      start_period = [repository.earliest_patient_recorded_at_period[region.slug], range.begin].compact.max
      calc_range = (start_period..range.end)
      result.period_info = calc_range.each_with_object({}) { |period, hsh| hsh[period] = period.to_hash }

      result.report_data_for(range)
    end

    def reporting_schema_v2?
      @reporting_schema_v2
    end

    private

    def repository
      @repository ||= Reports::Repository.new(region, periods: range, reporting_schema_v2: reporting_schema_v2?)
      # debugger
    end
  end
end
