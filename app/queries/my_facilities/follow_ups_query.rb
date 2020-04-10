class MyFacilities::FollowUpsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the Rails.application.config.country[:time_zone]
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`
  include QuarterHelper
  include MonthHelper
  include DayHelper
  include PeriodHelper

  attr_reader :periods

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month, :day.
    # last_n is the number of quarters/months/days data to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
  end

  def total_follow_ups
    date_truncate_string =
      "(DATE_TRUNC('day', bp_recorded_at::timestamptz AT TIME ZONE '#{Groupdate.time_zone || 'Etc/UTC'}'))"

    @total_follow_ups ||=
      LatestBloodPressuresPerPatientPerDay
        .where("patient_recorded_at < #{date_truncate_string}")
        .where(facility: @facilities)
  end

  def follow_ups
    case @period
      when :month
        monthly_follow_ups
      when :day
        daily_follow_ups
      else
        nil
    end
  end
  def monthly_follow_ups
    date_truncate_string =
      "(DATE_TRUNC('month', bp_recorded_at::timestamptz AT TIME ZONE '#{Groupdate.time_zone || 'Etc/UTC'}'))"

    @monthly_follow_ups ||=
      LatestBloodPressuresPerPatientPerMonth
        .where("patient_recorded_at < #{date_truncate_string}")
        .where(facility: @facilities)
        .where("(year, month) IN (#{periods_as_sql_list(pl)})")
  end

  def daily_follow_ups
    date_truncate_string =
      "(DATE_TRUNC('day', bp_recorded_at::timestamptz AT TIME ZONE '#{Groupdate.time_zone || 'Etc/UTC'}'))"

    @daily_follow_ups ||=
      LatestBloodPressuresPerPatientPerDay
        .where("patient_recorded_at < #{date_truncate_string}")
        .where(facility: @facilities)
        .where("(year, day) IN (#{periods_as_sql_list(@periods)})")
  end
end
