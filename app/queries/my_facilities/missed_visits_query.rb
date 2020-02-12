class MyFacilities::MissedVisitsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the ENV['ANALYTICS_TIME_ZONE']
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper

  attr_reader :periods

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month.
    # last_n is the number of quarters/months data to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
    @latest_period = @periods.first
  end

  def patients
    @patients ||=
      Patient
      .joins('INNER JOIN latest_blood_pressures_per_patients
              ON patients.id = latest_blood_pressures_per_patients.patient_id')
      .where(latest_blood_pressures_per_patients: { bp_facility_id: @facilities })
      .where('recorded_at < ?', Time.current.beginning_of_day - 2.months)
  end

  def patients_by_period
    @patients_by_period ||=
      @periods.map do |year, period|
        period_start = (@period == :quarter ? local_quarter_start(year, period) : local_month_start(year, period))
        [[year, period], patients.where('patient_recorded_at < ?', period_start - 2.months)]
      end.to_h
  end

  def visits_by_period
    @visits_by_period ||=
      patients_by_period.map do |key, patients|
        case @period
        when :quarter
          [key, visits_in_quarter(*key, patients)]
        when :month
          [key, visits_in_month(*key, patients)]
        end
      end.to_h
  end

  def calls_made
    period_start = (@period == :quarter ? local_quarter_start(*@latest_period) : local_month_start(*@latest_period))
    period_end = @period == :quarter ? period_start.end_of_quarter : period_start.end_of_month

    CallLog
      .result_completed
      .joins('INNER JOIN phone_number_authentications
              ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
      .joins('INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id')
      .where(phone_number_authentications: { registration_facility_id: @facilities })
      .where('call_logs.created_at >= ? AND call_logs.created_at <= ?', period_start, period_end)
      .group('facilities.id::uuid')
  end

  private

  def visits_in_quarter(year, quarter, patients)
    LatestBloodPressuresPerPatientPerQuarter
      .where(year: year, quarter: quarter)
      .where(patient_id: patients)
  end

  def visits_in_month(year, month, patients)
    LatestBloodPressuresPerPatientPerMonth
      .where(year: year, month: month)
      .where(patient_id: patients)
  end

  def period_list(period, last_n)
    case period
    when :quarter then
      last_n_quarters(n: last_n, inclusive: true)
    when :month then
      last_n_months(n: last_n, inclusive: true)
        .map { |month| [month.year, month.month] }
    end
  end
end
