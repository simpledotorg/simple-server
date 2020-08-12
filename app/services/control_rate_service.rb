class ControlRateService
  CACHE_VERSION = 6
  PERCENTAGE_PRECISION = 0

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
      @single_period = periods
      # If calling code is asking for a single period,
      # we set the range to be the current period to the start of the next period.
      Range.new(periods, periods.succ)
    else
      periods
    end
    @quarterly_report = @periods.begin.quarter?
    logger.info "#{self.class} created for periods: #{periods} facilities: #{facilities.map(&:id)} #{facilities.map(&:name)}"
  end

  def single_period?
    @single_period
  end

  delegate :logger, to: Rails
  attr_reader :facilities
  attr_reader :periods
  attr_reader :single_period
  attr_reader :region

  def call
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) do
      data = {
        controlled_patients: {},
        controlled_patients_rate: {},
        uncontrolled_patients: {},
        uncontrolled_patients_rate: {},
        registrations: {},
        cumulative_registrations: Hash.new(0)
      }

      data[:registrations] = registration_counts
      data[:cumulative_registrations] = sum_cumulative_registrations
      data[:registrations].delete_if { |period, value| !periods.cover?(period) }
      data[:cumulative_registrations].delete_if { |period, value| !periods.cover?(period) }

      periods.each do |(period, count)|
        controlled = controlled_patients(period).count
        uncontrolled = uncontrolled_patients(period).count

        data[:controlled_patients][period] = controlled
        data[:uncontrolled_patients][period] = uncontrolled

        # For quarterly reports the registration count is based on the cohort, so its from the previous period.
        registration_count = if quarterly_report?
          data[:registrations][period.previous] || 0
        else
          data[:cumulative_registrations][period]
        end

        data[:controlled_patients_rate][period] = percentage(controlled, registration_count)
        data[:uncontrolled_patients_rate][period] = percentage(uncontrolled, registration_count)
      end
      first_registration_period = registration_counts.keys.first
      if first_registration_period
        data.each { |(_key, hsh)| hsh.delete_if { |period, count| period < first_registration_period } }
      end
      data
    end
  end

  def sum_cumulative_registrations
    earliest_registration_period = [periods.begin, registration_counts.keys.first].compact.min
    (earliest_registration_period..periods.end).each_with_object({}) { |period, running_totals|
      previous_registrations = running_totals[period.previous] || 0
      current_registrations = registration_counts[period] || 0
      total = current_registrations + previous_registrations
      running_totals[period] = total
    }
  end

  def registration_counts
    return @registration_counts if @registration_counts
    formatter = lambda { |v| quarterly_report? ? Period.quarter(v) : Period.month(v) }
    result = region.registered_patients.with_hypertension.group_by_period(periods.begin.type, :recorded_at, {format: formatter}).count
    # The group_by_period query will only return values for months where we had registrations, but we want to
    # have a value for every month in the periods we are reporting on. So we iterate over every period and set
    # the count to 0 if there is no value.
    periods.each do |period|
      result[period] ||= 0
    end
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
    time = period.to_date
    end_range = time.end_of_month
    mid_range = time.advance(months: -1).end_of_month
    beg_range = time.advance(months: -2).end_of_month
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .with_hypertension
      .where(registration_facility_id: facilities)
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

  def percentage(numerator, denominator)
    return 0 if denominator == 0 || numerator == 0
    ((numerator.to_f / denominator) * 100).round(PERCENTAGE_PRECISION)
  end
end
