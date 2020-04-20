class UserAnalyticsPresenter
  include ApplicationHelper
  include HashUtilities
  include MonthHelper
  include DayHelper
  include PeriodHelper

  DAYS_AGO = 30
  MONTHS_AGO = 6
  TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  TROPHY_MILESTONE_INCR = 10_000
  EXPIRE_STATISTICS_CACHE_IN = 15.minutes

  attr_reader :daily_period_list, :monthly_period_list

  def initialize(current_facility)
    @current_facility = current_facility
    @daily_period_list = period_list_as_dates(:day, DAYS_AGO)
    @monthly_period_list = period_list_as_dates(:month, MONTHS_AGO)
  end

  def statistics
    @statistics ||=
      Rails.cache.fetch(statistics_cache_key, expires_in: EXPIRE_STATISTICS_CACHE_IN) do
        {
          daily: daily_stats,
          monthly: monthly_stats,
          all_time: all_time_stats,
          trophies: trophy_stats,
          metadata: {
            is_diabetes_enabled: false,
            last_updated_at: I18n.l(Time.current),
            formatted_next_date: display_date(Time.current + 1.day),
            today_string: I18n.t(:today_str)
          }
        }
      end
  end

  def display_percentage(numerator, denominator)
    return '0%' if denominator.nil? || denominator.zero? || numerator.nil?
    percentage = (numerator * 100.0) / denominator

    "#{percentage.round(0)}%"
  end

  private

  def daily_stats
    {
      grouped_by_date:
        {
          follow_ups: daily_follow_ups.count,
          registrations: daily_registrations.count
        }
    }
  end

  def monthly_stats
    {
      grouped_by_date:
        {
          follow_ups: monthly_follow_ups.count,
          registrations: monthly_registrations.count,
          controlled_visits: controlled_visits.count,
        },

      grouped_by_gender_and_date:
        {
          follow_ups: monthly_follow_ups_by_gender.count,
          registrations: monthly_registrations_by_gender.count
        },
    }
  end

  def all_time_stats
    {
      grouped_by_gender:
        {
          follow_ups: all_time_follow_ups_by_gender.count,
          registrations: all_time_registrations_by_gender.count
        }
    }
  end

  #
  # After exhausting the initial TROPHY_MILESTONES, subsequent milestones must follow the following pattern:
  #
  # 10
  # 25
  # 50
  # 100
  # 250
  # 500
  # 1_000
  # 2_000
  # 3_000
  # 4_000
  # 5_000
  # 10_000
  # 20_000
  # 30_000
  # etc.
  #
  # i.e. increment by TROPHY_MILESTONE_INCR
  def trophy_stats
    all_time_follow_ups = all_time_follow_ups_by_gender.count.values.sum

    all_trophies =
      all_time_follow_ups > TROPHY_MILESTONES.last ?
        [*TROPHY_MILESTONES,
         *(TROPHY_MILESTONE_INCR..(all_time_follow_ups + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)] :
        TROPHY_MILESTONES

    unlocked_trophies_until = all_trophies.index { |v| all_time_follow_ups < v }

    {
      locked_trophy_value:
        all_trophies[unlocked_trophies_until],

      unlocked_trophy_values:
        all_trophies[0, unlocked_trophies_until]
    }
  end

  def daily_follow_ups
    @current_facility.patient_follow_ups(:day, last: DAYS_AGO)
  end

  def daily_registrations
    @monthly_registrations ||=
      @current_facility
        .registered_patients
        .group_by_period(:day, :recorded_at, last: DAYS_AGO)
  end

  def monthly_follow_ups
    @monthly_follow_ups ||=
      @current_facility.patient_follow_ups(:month, last: MONTHS_AGO)
  end

  def monthly_follow_ups_by_gender
    @monthly_follow_ups.group(:gender)
  end

  def controlled_visits
    @monthly_follow_ups.merge(BloodPressure.under_control)
  end

  def monthly_registrations_by_gender
    @monthly_registrations.group(:gender)
  end

  def monthly_registrations
    @monthly_registrations ||=
      @current_facility
        .registered_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
  end

  def all_time_follow_ups_by_gender
    @all_time_follow_ups ||=
      @current_facility
        .patient_follow_ups(:month)
        .group(:gender)
  end

  def all_time_registrations_by_gender
    @all_time_registrations ||=
      @current_facility
        .registered_patients
        .group(:gender)
  end

  def fetch_for_date(period, last)
    last_n_periods(period, last).map do |date|
      [date.to_date, yield(date.to_date)]
    end.to_h
  end

  def statistics_cache_key
    "user_analytics/#{@current_facility.id}"
  end
end
