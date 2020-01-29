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
      LatestBloodPressuresPerPatient
        .where(bp_facility_id: @facilities)
        .where('patient_recorded_at < ?', Time.current.beginning_of_day - 2.months)
  end

  def patients_by_period
    registered_before =
      (@period == :quarter ? local_quarter_start(*@latest_period) - 2.months : local_month_start(*@latest_period) - 2.months)

    @patients_by_period ||=
      @periods.map do |year, period|
        [[year, period], patients.where('patient_recorded_at < ?', registered_before)]
      end.to_h
  end

  def visits_by_period
    @visits_by_period ||=
      patients_by_period.map do |key, patients|
        case @period
        when :quarter then
          [key,
           LatestBloodPressuresPerPatientPerQuarter
             .where("(year, #{@period}) IN (#{periods_as_sql_list})")
             .where(patient_id: patients.pluck(:patient_id))]
        when :month then
          [key,
           LatestBloodPressuresPerPatientPerMonth
             .where("(year, #{@period}) IN (#{periods_as_sql_list})")
             .where(patient_id: patients.pluck(:patient_id))]
        end
      end.to_h
  end

  def all_time_registrations
    @all_time_registrations ||=
      LatestBloodPressuresPerPatient
        .where(facility: @facilities)
        .where('patient_recorded_at < ?', Time.current.beginning_of_day - 2.months)
  end

  def calls_made
    period_start = (@period == :quarter ? local_quarter_start(*@latest_period) : local_month_start(*@latest_period))
    period_end = @period == :quarter ? period_start.end_of_quarter : period_start.end_of_month

    CallLog
      .result_completed
      .joins('INNER JOIN phone_number_authentications ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
      .joins('INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id')
      .where(phone_number_authentications: { registration_facility_id: @facilities })
      .where('call_logs.created_at >= ? AND call_logs.created_at <= ?', period_start, period_end)
      .group('facilities.id::uuid')
  end

  private

  def period_list(period, last_n)
    case period
    when :quarter then
      last_n_quarters(n: last_n, inclusive: true)
    when :month then
      last_n_months(n: last_n, inclusive: true)
        .map { |month| [month.year, month.month] }
    end
  end

  def periods_as_sql_list
    @periods.map { |(year, period)| "('#{year}', '#{period}')" }.join(',')
  end
end
