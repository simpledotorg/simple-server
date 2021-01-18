class ControlRateService
  CACHE_VERSION = 9

  # Can be initialized with _either_ a Period range or a single Period to calculate
  # control rates. We need to handle a single period for calculating point in time benchmarks.
  #
  # Note that for the range the returned values will be for each Period going back
  # to the beginning of registrations for the region.
  def initialize(region, periods:, with_exclusions: false)
    @region = region
    @facilities = region.facilities
    # Normalize between a single period and range of periods
    @report_range = if !periods.is_a?(Range)
      # If calling code is asking for a single period,
      # we set the range to be the current period to the start of the next period.
      Range.new(periods, periods.succ)
    else
      periods
    end
    @quarterly_report = @report_range.begin.quarter?
    @results = Reports::Result.new(region: @region, period_type: @report_range.begin.type)
    @with_exclusions = with_exclusions
    logger.info class: self.class.name, msg: "created", region: region.id, region_name: region.name,
                report_range: report_range.inspect, facilities: facilities.map(&:id), cache_key: cache_key
  end

  delegate :logger, to: Rails
  attr_reader :facilities
  attr_reader :region
  attr_reader :report_range
  attr_reader :results
  attr_reader :with_exclusions

  # We cache all the data for a region to improve performance and cache hits, but then return
  # just the data the client requested
  def call
    all_cached_data.report_data_for(report_range)
  end

  private

  def all_cached_data
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) {
      fetch_all_data
    }
  end

  def fetch_all_data
    results.registrations = registration_counts
    results.registrations_with_exclusions = registration_counts_with_exclusions
    results.earliest_registration_period = registration_counts.keys.first
    results.fill_in_nil_registrations
    results.count_adjusted_registrations
    results.count_cumulative_registrations

    results.full_data_range.each do |(period, count)|
      results.controlled_patients[period] = controlled_patients(period).count
      results.uncontrolled_patients[period] = uncontrolled_patients(period).count
    end

    results.calculate_percentages(:controlled_patients)
    results.calculate_percentages(:uncontrolled_patients)
    results
  end

  def registration_counts_with_exclusions
    return @registration_counts_with_exclusions if defined? @registration_counts_with_exclusions
    formatter = lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }

    @registration_counts_with_exclusions =
      region.assigned_patients
        .for_reports(with_exclusions: with_exclusions)
        .group_by_period(report_range.begin.type, :recorded_at, {format: formatter})
        .count
  end

  def registration_counts
    return @registration_counts if defined? @registration_counts
    formatter = lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }

    @registration_counts =
      region.assigned_patients
        .group_by_period(report_range.begin.type, :recorded_at, {format: formatter})
        .count
  end

  def controlled_patients(period)
    if period.quarter?
      bp_quarterly_query(period).under_control
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_monthly_query(period),
        "latest_blood_pressures_per_patient_per_months").under_control
    end
  end

  def bp_monthly_query(period)
    control_range = period.blood_pressure_control_range
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .for_reports(with_exclusions: with_exclusions)
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .where(assigned_facility_id: facilities)
      .where("patient_recorded_at < ?", control_range.begin) # TODO this doesn't seem right -- revisit this exclusion
      .where("bp_recorded_at > ? and bp_recorded_at <= ?", control_range.begin, control_range.end)
      .order("latest_blood_pressures_per_patient_per_months.patient_id, bp_recorded_at DESC, bp_id")
  end

  def uncontrolled_patients(period)
    if period.quarter?
      bp_quarterly_query(period).hypertensive
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_monthly_query(period),
        "latest_blood_pressures_per_patient_per_months").hypertensive
    end
  end

  def bp_quarterly_query(period)
    quarter = period.value
    cohort_quarter = quarter.previous_quarter
    LatestBloodPressuresPerPatientPerQuarter
      .for_reports(with_exclusions: with_exclusions)
      .where(assigned_facility_id: facilities)
      .where(year: quarter.year, quarter: quarter.number)
      .where("patient_recorded_at >= ? and patient_recorded_at <= ?", cohort_quarter.beginning_of_quarter, cohort_quarter.end_of_quarter)
      .order("patient_id, bp_recorded_at DESC, bp_id")
  end

  def quarterly_report?
    @quarterly_report
  end

  def cache_key
    if with_exclusions
      "#{self.class}/#{region.cache_key}/#{report_range.begin.type}/#{Date.current}/with_exclusions"
    else
      "#{self.class}/#{region.cache_key}/#{report_range.begin.type}/#{Date.current}"
    end
  end

  def cache_version
    "#{region.cache_version}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
