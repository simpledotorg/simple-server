class MyFacilities::FollowUpsQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the Rails.application.config.country[:time_zone]
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_registrations }`

  include QuarterHelper
  include MonthHelper
  include DayHelper
  include PeriodHelper

  attr_reader :periods

  def self.total_follow_ups(facilities)
    LatestBloodPressuresPerPatientPerDay
      .where('patient_recorded_at < bp_recorded_at')
      .where(facility: facilities)
  end

  def initialize(facilities: Facility.all, period: :quarter, last_n: 3)
    # period can be :quarter, :month, :day.
    # last_n is the number of quarters/months/days data to be returned
    @facilities = facilities
    @period = period
    @periods = period_list(period, last_n)
  end

  def follow_ups
    MyFacilities::FollowUpsQuery
      .total_follow_ups(@facilities)
      .where("(year, #{@period}) IN (#{periods_as_sql_list(@periods)})")
  end
end
