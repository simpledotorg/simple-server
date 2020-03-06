class MyFacilities::MissedVisitsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the Rails.application.config.country[:time_zone]
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper

  REGISTRATION_BUFFER = 2.months

  attr_reader :periods

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month.
    # last_n is the number of quarters/months for which data is to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
    @latest_period = @periods.first
  end

  def patients
    @patients ||=
      Patient
      .where(registration_facility_id: @facilities)
      .where('recorded_at < ?', Time.current.beginning_of_day - REGISTRATION_BUFFER)
  end

  def patients_by_period
    @patients_by_period ||=
      @periods.map do |year, period|
        period_start = (@period == :quarter ? local_quarter_start(year, period) : local_month_start(year, period))
        [[year, period], patients.where('recorded_at < ?', period_start - REGISTRATION_BUFFER)]
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

    @calls_made ||=
      CallLog
      .result_completed
      .joins('INNER JOIN phone_number_authentications
              ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
      .joins('INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id')
      .where(phone_number_authentications: { registration_facility_id: @facilities })
      .where('call_logs.created_at >= ? AND call_logs.created_at <= ?', period_start, period_end)
      .group('facilities.id::uuid')
  end

  def missed_visits_by_facility
    @missed_visits_by_facility ||=
      patients_by_period.map do |(year, period), patients|
        responsible_patients = patients.group(:registration_facility_id).count
        visited_patients = visits_by_period[[year, period]].group(:registration_facility_id).count

        responsible_patients.map do |facility_id, patient_count|
          [[facility_id, year, period],
           { patients: patient_count.to_i,
             missed: patient_count.to_i - visited_patients[facility_id].to_i }]
        end.to_h
      end.reduce(:merge)
  end

  def missed_visit_totals
    @missed_visit_totals ||=
      missed_visits_by_facility.each_with_object({}) do |(key, missed_visit_data), total_missed_visit_data|
        period = [key.second.to_i, key.third.to_i]
        total_missed_visit_data[period] ||= {}

        total_missed_visit_data[period][:patients] ||= 0
        total_missed_visit_data[period][:patients] += missed_visit_data[:patients]

        total_missed_visit_data[period][:missed] ||= 0
        total_missed_visit_data[period][:missed] += missed_visit_data[:missed]
      end
  end

  private

  def visits_in_quarter(year, quarter, patients)
    LatestBloodPressuresPerPatientPerQuarter
      .where(year: year, quarter: quarter, patient: patients)
  end

  def visits_in_month(year, month, patients)
    LatestBloodPressuresPerPatientPerMonth
      .where(year: year, month: month, patient: patients)
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
