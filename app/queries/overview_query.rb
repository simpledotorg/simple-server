# frozen_string_literal: true

class OverviewQuery
  # Wrap query method calls with the appropriate timezone in which the reports will be consumed
  # This is probably the Rails.application.config.country[:time_zone]
  # Example: `Time.use_zone('timezone string') { bp_control_query_object.cohort_patients }`
  include DayHelper

  INACTIVITY_THRESHOLD_DAYS = 30
  INACTIVITY_THRESHOLD_BPS = 1

  attr_reader :facilities

  def initialize(facilities: Facility.all)
    @facilities = Facility.where(id: facilities)
  end

  def total_bps_in_last_n_days(n: INACTIVITY_THRESHOLD_DAYS)
    bps_per_day_in_last_n_days(n: n)
      .select(:facility_id)
      .group(:facility_id)
      .sum(:bp_count)
  end

  def inactive_facilities
    active_facilities = bps_per_day_in_last_n_days(n: INACTIVITY_THRESHOLD_DAYS)
      .group(:facility_id)
      .having("SUM(bp_count) >= ?", INACTIVITY_THRESHOLD_BPS)

    @inactive_facilities ||= facilities.where.not(id: active_facilities.pluck(:facility_id))
  end

  private

  def bps_per_day_in_last_n_days(n:)
    days_list = days_as_sql_list(last_n_days(n: n))
    BloodPressuresPerFacilityPerDay
      .where(facility: facilities)
      .where("((year, day) IN (#{days_list}))")
  end

  def days_as_sql_list(days)
    days.map { |(year, day)| "('#{year}', '#{day}')" }.join(",")
  end
end
