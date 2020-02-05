class MyFacilities::RegistrationsQuery
  include QuarterHelper
  include MonthHelper
  include DayHelper

  attr_reader :periods

  def initialize(period: :quarter, facilities: Facility.all, include_quarters: 3, include_months: 3, include_days: 7)
    @facilities = facilities
    @period = period
    @periods = case period
               when :quarter then last_n_quarters(n: include_quarters, inclusive: true)
               when :month then
                 last_n_months(n: include_months, inclusive: true)
                 .map { |month| [month.year, month.month] }
               when :day then last_n_days(n: include_days)
               end
  end

  def registrations
    case @period
    when :quarter then quarterly_registrations
    when :month then monthly_registrations
    when :day then daily_registrations
    end
  end

  def all_time_registrations
    LatestBloodPressuresPerPatient
      .where(facility: @facilities)
      .where('patient_recorded_at < ?', Time.current.beginning_of_day - 2.months)
  end

  private

  def quarterly_registrations
    year_quarter_tuples = @periods.map { |(year, quarter)| "('#{year}', '#{quarter}')" }.join(',')

    PatientRegistrationsPerDayPerFacility
      .where(facility: @facilities)
      .where("(year, quarter) IN (#{year_quarter_tuples})")
  end

  def monthly_registrations
    year_month_tuples = @periods.map { |(year, month)| "('#{year}', '#{month}')" }.join(',')

    PatientRegistrationsPerDayPerFacility
      .where(facility: @facilities)
      .where("(year, month) IN (#{year_month_tuples})")
  end

  def daily_registrations
    year_day_tuples = @periods.map { |(year, day)| "('#{year}', '#{day}')" }.join(',')

    PatientRegistrationsPerDayPerFacility
      .where(facility: @facilities)
      .where("(year, day) IN (#{year_day_tuples})")
  end
end
