class ControlRateService
  CACHE_VERSION = 1
  PERCENTAGE_PRECISION = 1

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
      Range.new(periods, periods)
    else
      periods
    end
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
      data[:registrations].each { |period, count| data[:cumulative_registrations][period] += count }
      data[:registrations].each do |(period, count)|
        data[:controlled_patients][period] = controlled_patients(period).count
        registrations = if quarterly_report?
          previous_quarter = period.advance(months: -3)
          data[:registrations][previous_quarter] || 0
        else
          count
        end
        data[:controlled_patients_rate][period] = percentage(controlled_patients(period).count, registrations)
        data[:uncontrolled_patients][period] = uncontrolled_patients(period).count
        data[:uncontrolled_patients_rate][period] = percentage(uncontrolled_patients(period).count, registrations)
      end
      data
    end
  end

  def lookup_registrations(period)
    registration_counts[period]
  end

  def quarterly_report?
    periods.begin.quarter?
  end

  def registration_counts
    @registration_counts ||= if single_period
      count = region.registered_patients.with_hypertension.where("recorded_at <= ?", single_period.to_date).count
      {
        single_period => count
      }
    else
      range = periods.begin.value.to_date..periods.end.value.to_date
      region.registered_patients.with_hypertension.group_by_period(periods.begin.type,
        :recorded_at, { range: range, format: ->(v) { quarterly_report? ? Period.quarter(v) : Period.month(v) }})
        .count
    end
  end

  def controlled_patients(period)
    if period.quarter?
      bp_quarterly_query(period).under_control
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_query(period).under_control,
        "latest_blood_pressures_per_patient_per_months")
    end
  end

  def uncontrolled_patients(period)
    if period.quarter?
      bp_quarterly_query(period).hypertensive
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_query(period).hypertensive,
        "latest_blood_pressures_per_patient_per_months")
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

  def bp_query(period)
    time = period.value
    end_range = time.end_of_month
    mid_range = time.advance(months: -1).end_of_month
    beg_range = time.advance(months: -2).end_of_month
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .with_hypertension
      .order("latest_blood_pressures_per_patient_per_months.patient_id, bp_recorded_at DESC, bp_id")
      .where(registration_facility_id: facilities)
      .where("(year = ? AND month = ?) OR (year = ? AND month = ?) OR (year = ? AND month = ?)",
        beg_range.year.to_s, beg_range.month.to_s,
        mid_range.year.to_s, mid_range.month.to_s,
        end_range.year.to_s, end_range.month.to_s)
  end

  private

  def cache_key
    "#{self.class}/#{region.model_name}/#{region.id}/#{periods.begin.type}_periods/#{periods_cache_key}"
  end

  def periods_cache_key
    if periods.is_a?(Range)
      "#{periods.begin.value}/#{periods.end.value}"
    else
      period.value
    end
  end

  def cache_version
    "#{region.updated_at.utc.to_s(:usec)}/#{CACHE_VERSION}"
  end

  def force_cache?
    RequestStore.store[:force_cache]
  end

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    ((numerator.to_f / denominator) * 100).truncate(PERCENTAGE_PRECISION)
  end
end
