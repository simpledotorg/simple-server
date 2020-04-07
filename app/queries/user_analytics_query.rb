class UserAnalyticsQuery
  include DayHelper
  include MonthHelper
  include PeriodHelper

  def initialize(facility, days_ago: 30, months_ago: 6, fetch_until: Date.current)
    @current_facility = facility
    @days_ago = days_ago
    @months_ago = months_ago
    @fetch_until = fetch_until

    @monthly_follow_ups_data =
      MyFacilities::FollowUpsQuery
        .new(facilities: @current_facility, period: :month, last_n: @months_ago)
        .follow_ups
  end

  def daily_follow_ups
    MyFacilities::FollowUpsQuery
      .new(facilities: @current_facility, period: :day, last_n: @days_ago)
      .follow_ups
      .group(:year, :day)
      .count
      .map { |group, count| [doy_to_date(*group), count] }
      .to_h
  end

  def daily_registrations
    group_by_time_range = (@days_ago.to_i - 1).days.ago.beginning_of_day..@fetch_until

    @current_facility
      .registered_patients
      .group_by_period(:day, :recorded_at, range: group_by_time_range)
      .distinct('patients.id')
      .count
  end

  def monthly_follow_ups
    @monthly_follow_ups_data
      .joins(:patient)
      .group(:gender, :year, :month)
      .count
      .map { |(gender, year, month), count| [[gender, moy_to_date(year, month)], count] }
      .to_h
  end

  def monthly_registrations
    group_by_time_range = (@months_ago.to_i - 1).months.ago.beginning_of_month..@fetch_until

    @current_facility
      .registered_patients
      .group(:gender)
      .group_by_period(:month, :recorded_at, range: group_by_time_range)
      .distinct('patients.id')
      .count
      .map { |(gender, date), count| [[gender, date], count] }
      .to_h
  end

  def monthly_htn_control
    total_visits =
      @monthly_follow_ups_data
        .group(:year, :month)
        .count
        .map { |group, count| [moy_to_date(*group), count] }
        .to_h

    controlled_visits =
      @monthly_follow_ups_data
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
      .new(facilities: @current_facility)
      .total_follow_ups
      .joins(:patient)
      .group(:gender)
      .count
  end

  def all_time_registrations
    @current_facility
      .registered_patients
      .group(:gender)
      .distinct('patients.id')
      .count
  end
end
