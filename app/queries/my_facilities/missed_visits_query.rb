class MyFacilities::MissedVisitsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the Rails.application.config.country[:time_zone]
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper

  attr_reader :periods

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month.
    # last_n is the number of quarters/months for which data is to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
    @latest_period = @periods.first
    @last_n = last_n
  end

  def calls_made
    period_start = (@period == :quarter ? local_quarter_start(*@latest_period) : local_month_start(*@latest_period))
    period_end = @period == :quarter ? period_start.end_of_quarter : period_start.end_of_month

    @calls_made ||=
      CallLog
        .result_completed
        .joins('INNER JOIN phone_number_authentications
              ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
        .joins("INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id")
        .where(phone_number_authentications: {registration_facility_id: @facilities})
        .where("call_logs.created_at >= ? AND call_logs.created_at <= ?", period_start, period_end)
        .group("facilities.id::uuid")
  end

  def bp_query_by_cohort
    @bp_query_by_cohort ||=
      @periods.map { |year, period|
        bp_query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities,
                                                               cohort_period: {cohort_period: @period,
                                                                               registration_year: year,
                                                                               registration_month: period,
                                                                               registration_quarter: period})
        [[year, period], bp_query]
      }.to_h
  end

  def missed_visits_by_facility
    @missed_visits_by_facility ||=
      bp_query_by_cohort.map { |(year, period), bp_query|
        bp_query.cohort_patients_per_facility.map { |facility_id, patient_count|
          [[facility_id, year, period],
            {patients: patient_count.to_i,
             missed: bp_query.cohort_missed_visits_count_by_facility[facility_id].to_i}]
        }.to_h
      }.reduce(:merge)
  end

  def missed_visit_totals
    @missed_visit_totals ||=
      bp_query_by_cohort.map { |(year, period), bp_query|
        cohort_registrations = bp_query.cohort_registrations.count
        cohort_missed_visits_count = bp_query.cohort_missed_visits_count
        [[year, period],
          {patients: cohort_registrations.to_i,
           missed: cohort_missed_visits_count.to_i}]
      }.to_h
  end

  def total_patients
    bp_query = MyFacilities::BloodPressureControlQuery.new(facilities: @facilities)
    @total_patients ||= bp_query.overall_patients_per_facility
  end

  private

  def period_list(period, last_n)
    case period
    when :quarter then
      last_n_quarters(n: last_n, inclusive: false)
    when :month then
      last_n_months(n: last_n, inclusive: false)
        .map { |month| [month.year, month.month] }
    end
  end
end
