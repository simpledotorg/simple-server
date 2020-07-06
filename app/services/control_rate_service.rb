class ControlRateService
  PERCENTAGE_PRECISION = 1

  def initialize(region, range: nil, date: nil)
    @region = region
    @facilities = if @region.respond_to?(:facilities)
      @region.facilities
    else
      [region]
    end
    raise ArgumentError, "Cannot provide both a range and date" if range && date
    @range = range
    @date = date
    @end_of_date_range = date || range.end
    logger.info "#{self.class} created for range: #{range} region: #{region.id} #{region.name}"
  end

  delegate :logger, to: Rails
  attr_reader :date
  attr_reader :facilities
  attr_reader :range
  attr_reader :region

  def call
    data = {
      controlled_patients: {},
      controlled_patients_rate: {},
      registrations: {}
    }

    data[:cumulative_registrations] = registrations(@end_of_date_range)
    registration_counts.each do |(date, count)|
      formatted_period = date.to_s(:month_year)
      data[:controlled_patients][formatted_period] = controlled_patients(date).count
      data[:controlled_patients_rate][formatted_period] = percentage(controlled_patients(date).count, count)
      data[:registrations][formatted_period] = count
    end
    data
  end

  def registrations(time)
    registration_counts[time.beginning_of_month.to_date]
  end

  def registration_counts
    if range
      @registration_counts ||= region.patients.with_hypertension
        .group_by_period(:month, :recorded_at, range: range)
        .count
        .each_with_object(Hash.new(0)) { |(date, count), hsh|
          hsh[:running_total] += count
          hsh[date] = hsh[:running_total]
        }.delete_if { |date, count| count == 0 }.except(:running_total)
    else
      @registration_counts ||= { date => region.patients.with_hypertension.where("recorded_at <= ?", date).count }
    end
  end

  def controlled_patients(time)
    end_range = time.end_of_month
    mid_range = time.advance(months: -1).end_of_month
    beg_range = time.advance(months: -2).end_of_month
    # We need to avoid the default scope to avoid ambiguous column errors, hence the `with_discarded`
    # Note that the deleted_at scoping piece is applied when the SQL view is created, so we don't need to worry about it here
    sub_query = LatestBloodPressuresPerPatientPerMonth
      .with_discarded
      .select("distinct on (latest_blood_pressures_per_patient_per_months.patient_id) *")
      .under_control
      .with_hypertension
      .order("latest_blood_pressures_per_patient_per_months.patient_id, bp_recorded_at DESC, bp_id")
      .where(registration_facility_id: facilities)
      .where("(year = ? AND month = ?) OR (year = ? AND month = ?) OR (year = ? AND month = ?)",
        beg_range.year.to_s, beg_range.month.to_s,
        mid_range.year.to_s, mid_range.month.to_s,
        end_range.year.to_s, end_range.month.to_s)
    LatestBloodPressuresPerPatientPerMonth.with_discarded.from(sub_query, "latest_blood_pressures_per_patient_per_months")
  end

  private

  def percentage(numerator, denominator)
    return 0 if denominator == 0
    ((numerator.to_f / denominator) * 100).truncate(PERCENTAGE_PRECISION)
  end
end
