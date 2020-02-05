class MyFacilities::RegistrationsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the ENV['ANALYTICS_TIME_ZONE']
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper
  include DayHelper

  attr_reader :periods

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month, :day.
    # last_n is the number of quarters/months/days data to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
  end

  def registrations
    @registrations ||=
      PatientRegistrationsPerDayPerFacility
      .where(facility: @facilities)
      .where("(year, #{@period}) IN (#{periods_as_sql_list})")
  end

  def all_time_registrations
    @all_time_registrations ||=
      LatestBloodPressuresPerPatient
      .where(facility: @facilities)
      .where('patient_recorded_at < ?', Time.current.beginning_of_day - 2.months)
  end

  private

  def period_list(period, last_n)
    case period
    when :quarter then last_n_quarters(n: last_n, inclusive: true)
    when :month then
      last_n_months(n: last_n, inclusive: true)
        .map { |month| [month.year, month.month] }
    when :day then last_n_days(n: last_n)
    end
  end

  def periods_as_sql_list
    @periods.map { |(year, day)| "('#{year}', '#{day}')" }.join(',')
  end
end
