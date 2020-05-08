class MyFacilities::RegistrationsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the Rails.application.config.country[:time_zone]
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper
  include DayHelper

  attr_reader :periods

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month, :day.
    # last_n is the number of quarters/months/days for which data is to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
  end

  # htn-only
  def registrations
    @registrations ||=
      PatientRegistrationsPerDayPerFacility
        .where(facility: @facilities)
        .where("(year, #{@period}) IN (#{periods_as_sql_list})")
  end

  def total_registrations
    @total_registrations ||=
      Patient
        .hypertension_only
        .where(registration_facility: @facilities)
  end

  private

  def period_list(period, last_n)
    case period
      when :quarter then
        last_n_quarters(n: last_n, inclusive: true)
      when :month then
        last_n_months(n: last_n, inclusive: true)
          .map { |month| [month.year, month.month] }
      when :day then
        last_n_days(n: last_n)
    end
  end

  def periods_as_sql_list
    @periods.map { |year, period| "('#{year}', '#{period}')" }.join(',')
  end
end
