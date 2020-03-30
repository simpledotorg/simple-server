class UserAnalyticsQuery
  include DayHelper
  include MonthHelper
  include PeriodHelper

  attr_reader :current_facility, :days_ago, :months_ago

  def initialize(facility, days_ago: 30, months_ago: 6)
    @current_facility = facility
    @days_ago = days_ago
    @months_ago = months_ago
  end

  def daily_follow_ups
    MyFacilities::FollowUpsQuery
      .new(facilities: current_facility, period: :day, last_n: days_ago)
      .follow_ups
      .group(:year, :day)
      .count
      .map { |group, count| [doy_to_date(*group), count] }
      .to_h
  end

  def daily_registrations
    current_facility
      .registered_patients
      .group_by_period(:day, :recorded_at, last: days_ago)
      .distinct('patients.id')
      .count
  end

  def monthly_follow_ups
    MyFacilities::FollowUpsQuery
      .new(facilities: current_facility, period: :month, last_n: months_ago)
      .follow_ups
      .joins(:patient)
      .group(:gender, :year, :month)
      .count
      .map { |(gender, year, month), count| [[gender, moy_to_date(year, month)], count] }
      .to_h
  end

  def monthly_registrations
    current_facility
      .registered_patients
      .group(:gender)
      .group_by_period(:month, :recorded_at, last: months_ago)
      .distinct('patients.id')
      .count
      .map { |(gender, date), count| [[gender, date], count] }
      .to_h
  end

  def monthly_htn_control
    visits =
      LatestBloodPressuresPerPatientPerDay
        .where(facility: current_facility)
        .where("(year, month) IN (#{periods_as_sql_list(period_list(:month, months_ago))})")

    total_visits =
      visits
        .group(:year, :month)
        .count
        .map { |group, count| [moy_to_date(*group), count] }
        .to_h

    controlled_visits =
      visits
        .under_control
        .group(:year, :month)
        .count
        .map { |group, count| [moy_to_date(*group), count] }
        .to_h

    { total_visits: total_visits,
      controlled_visits: controlled_visits }
  end

  def all_time_follow_ups
    MyFacilities::FollowUpsQuery
      .new(facilities: current_facility)
      .total_follow_ups
      .joins(:patient)
      .group(:gender)
      .count
  end

  def all_time_registrations
    current_facility
      .registered_patients
      .group(:gender)
      .distinct('patients.id')
      .count
  end
end
