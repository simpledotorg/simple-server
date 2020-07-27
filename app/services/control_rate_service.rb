class ControlRateService
  CACHE_VERSION = 1
  PERCENTAGE_PRECISION = 1

  # Can be initialized with _either_ a date range or a single date to calculate
  # control rates. Note that for the date range the returned values will be for each month going back
  # to the beginning of registrations for the region.
  def initialize(region, range: nil, period: "month", date: nil)
    raise ArgumentError, "Cannot provide both a range and date" if range && date
    raise ArgumentError, "Must provide either a range or a single date" if range.nil? && date.nil?
    @region = region
    @facilities = region.facilities
    @range = range
    @period = period
    @date = date
    @end_of_date_range = date || range.end
    logger.info "#{self.class} created for range: #{range} facilities: #{facilities.map(&:id)} #{facilities.map(&:name)}"
  end

  delegate :logger, to: Rails
  attr_reader :date
  attr_reader :facilities
  attr_reader :period
  attr_reader :range
  attr_reader :region

  def call
    Rails.cache.fetch(cache_key, version: cache_version, expires_in: 7.days, force: force_cache?) do
      data = {
        controlled_patients: {},
        controlled_patients_rate: {},
        uncontrolled_patients: {},
        uncontrolled_patients_rate: {},
        registrations: {}
      }

      data[:cumulative_registrations] = registrations(@end_of_date_range)
      registration_counts.each do |(date, count)|
        formatted_period = date.is_a?(Quarter) ? date : date.to_s(:month_year)
        data[:controlled_patients][formatted_period] = controlled_patients(date).count
        data[:uncontrolled_patients][formatted_period] = uncontrolled_patients(date).count
        data[:uncontrolled_patients_rate][formatted_period] = percentage(uncontrolled_patients(date).count, count)
        data[:controlled_patients_rate][formatted_period] = percentage(controlled_patients(date).count, count)
        data[:registrations][formatted_period] = count
      end
      data
    end
  end

  def registrations(time)
    registration_counts[time.beginning_of_month.to_date]
  end

  def quarterly_period?
    period == "quarter"
  end

  # Calculate all registration counts for entire range, or for the single date provided
  def registration_counts
    @registration_counts ||= if range
      quarter_proc = lambda { |date| Quarter.new(date: date) }
      options = {range: range}
      options.merge!(format: quarter_proc) if quarterly_period?

      region.registered_patients.with_hypertension
        .group_by_period(period, :recorded_at, options)
        .count
        .each_with_object(Hash.new(0)) { |(date, count), hsh|
          hsh[:running_total] += count
          hsh[date] = hsh[:running_total]
        }.delete_if { |date, count| count == 0 }.except(:running_total)
    else
      count = region.registered_patients.with_hypertension.where("recorded_at <= ?", date).count
      {
        date => count
      }
    end
  end

  def controlled_patients(date_or_quarter)
    if date_or_quarter.is_a?(Quarter)
      bp_quarterly_query(date_or_quarter).under_control
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_query(date_or_quarter).under_control,
        "latest_blood_pressures_per_patient_per_months")
    end
  end

  def uncontrolled_patients(date_or_quarter)
    if date_or_quarter.is_a?(Quarter)
      bp_quarterly_query(date_or_quarter).hypertensive
    else
      LatestBloodPressuresPerPatientPerMonth.with_discarded.from(bp_query(date_or_quarter).hypertensive,
        "latest_blood_pressures_per_patient_per_months")
    end
  end

  def bp_quarterly_query(quarter)
    Rails.logger.info " ===> quarter #{quarter} number #{quarter.number}"
    LatestBloodPressuresPerPatientPerQuarter
      .where(registration_facility_id: facilities)
      .where(year: quarter.year, quarter: quarter.number)
      .with_hypertension
      .order("patient_id, bp_recorded_at DESC, bp_id")
  end

  def bp_query(time)
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
    "#{self.class}/#{region.model_name}/#{region.id}/#{date_or_range_cache_key}"
  end

  def date_or_range_cache_key
    if range
      "#{range.min.to_s(:iso8601)}/#{range.max.to_s(:iso8601)}"
    else
      date.to_s(:iso8601)
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
