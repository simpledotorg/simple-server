class ControlRateService
  CACHE_VERSION = 8

  # Can be initialized with _either_ a Period range or a single Period to calculate
  # control rates. We need to handle a single period for calculating point in time benchmarks.
  #
  # Note that for the range the returned values will be for each Period going back
  # to the beginning of registrations for the region.
  def initialize(region, periods:)
    @region = region
    @facilities = region.facilities
    # Normalize between a single period and range of periods
    @periods = if !periods.is_a?(Range)
      # If calling code is asking for a single period,
      # we set the range to be the current period to the start of the next period.
      Range.new(periods, periods.succ)
    else
      periods
    end
    @quarterly_report = @periods.begin.quarter?
    @results = Reports::Result.new(@periods)
    logger.info "#{self.class} created for periods: #{periods} facilities: #{facilities.map(&:id)} #{facilities.map(&:name)}"
  end

  delegate :logger, to: Rails
  attr_reader :facilities
  attr_reader :periods
  attr_reader :region
  attr_reader :results

  def call
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) do
      results.registrations = registration_counts
      results.cumulative_registrations = sum_cumulative_registrations
      results.count_adjusted_registrations

      periods.each do |(period, count)|
        results.controlled_patients[period] = controlled_patients(period).count
        results.uncontrolled_patients[period] = uncontrolled_patients(period).count
      end

      results.calculate_percentages(:controlled_patients)
      results.calculate_percentages(:uncontrolled_patients)
      results
    end
  end

  def sum_cumulative_registrations
    earliest_registration_period = [periods.begin, registration_counts.keys.first].compact.min
    (earliest_registration_period..periods.end).each_with_object(Hash.new(0)) { |period, running_totals|
      previous_registrations = running_totals[period.previous]
      current_registrations = registration_counts[period]
      total = current_registrations + previous_registrations
      running_totals[period] = total
    }
  end

  def registration_counts
    return @registration_counts if defined? @registration_counts
    formatter = lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }
    result = region.registered_patients.with_hypertension.group_by_period(periods.begin.type, :recorded_at, {format: formatter}).count
    # The group_by_period query will only return values for months where we had registrations, but we want to
    # have a value for every month in the periods we are reporting on. So we set the default to 0 for results.
    result.default = 0
    @registration_counts = result
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
    date = period.to_date
    end_range = date.end_of_month
    mid_range = date.advance(months: -1).end_of_month
    beg_range = date.advance(months: -2).end_of_month
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .with_hypertension
      .where(registration_facility_id: facilities)
      .where("patient_recorded_at < ?", period.blood_pressure_control_range.begin)
      .where("(year = ? AND month = ?) OR (year = ? AND month = ?) OR (year = ? AND month = ?)",
        beg_range.year.to_s, beg_range.month.to_s,
        mid_range.year.to_s, mid_range.month.to_s,
        end_range.year.to_s, end_range.month.to_s)
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
    Rails.logger.info " ===> quarter #{period} number #{quarter.number}"
    LatestBloodPressuresPerPatientPerQuarter
      .where(registration_facility_id: facilities)
      .where(year: quarter.year, quarter: quarter.number)
      .where("patient_recorded_at >= ? and patient_recorded_at <= ?", cohort_quarter.beginning_of_quarter, cohort_quarter.end_of_quarter)
      .with_hypertension
      .order("patient_id, bp_recorded_at DESC, bp_id")
  end

  private

  def quarterly_report?
    @quarterly_report
  end

  def cache_key
    "#{self.class}/#{region.model_name}/#{region.id}/#{periods_cache_key}"
  end

  def periods_cache_key
    value = if periods.is_a?(Range)
      "#{periods.begin.value}/#{periods.end.value}"
    else
      period.value
    end
    "#{periods.begin.type}_periods/#{value}"
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end
end
