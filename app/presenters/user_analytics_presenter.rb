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

  def stats_across_genders_for_month(resource, month_date)
    data_for_resource = statistics.dig(:monthly, :grouped_by_gender_and_date, resource).values

    sum_across_gender_and_months =
      data_for_resource.inject do |by_month, count_for_gender|
        by_month.merge(count_for_gender) { |_, v1, v2| v1 + v2 }
      end

    sum_across_gender_and_months&.dig(month_date)
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
          follow_ups: daily_follow_ups,
          registrations: daily_registrations
        }
    }
  end

  def monthly_stats
    {
      grouped_by_gender_and_date:
        {
          follow_ups: monthly_follow_ups,
          registrations: monthly_registrations
        },

      grouped_by_date:
        {
          total_visits: monthly_visits,
          controlled_visits: controlled_visits,
        }
    }
  end

  def all_time_stats
    {
      grouped_by_gender:
        {
          follow_ups: all_time_follow_ups,
          registrations: all_time_registrations
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
    total_follow_ups = @current_facility.all_follow_ups.count

    all_trophies =
      total_follow_ups > TROPHY_MILESTONES.last ?
        [*TROPHY_MILESTONES,
         *(TROPHY_MILESTONE_INCR..(total_follow_ups + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)] :
        TROPHY_MILESTONES

    unlocked_trophies_until = all_trophies.index { |v| total_follow_ups < v }

    {
      locked_trophy_value:
        all_trophies[unlocked_trophies_until],

      unlocked_trophy_values:
        all_trophies[0, unlocked_trophies_until]
    }
  end

  def daily_follow_ups
    fetch_for_date(:day, DAYS_AGO) do |date|
      @current_facility
        .patient_follow_ups(:day, date)
        .count
    end
  end

  def daily_registrations
    fetch_for_date(:day, DAYS_AGO) do |date|
      @current_facility
        .registered_patients
        .where(recorded_at: date.all_day)
        .count
    end
  end

  def monthly_follow_ups
    fetch_for_date(:month, MONTHS_AGO) do |date|
      @current_facility
        .patient_follow_ups(:month, date)
        .group(:gender)
        .count
    end
  end

  def monthly_visits
    fetch_for_date(:month, MONTHS_AGO) do |date|
      @current_facility
        .patient_follow_ups(:month, date)
        .count
    end
  end

  def controlled_visits
    fetch_for_date(:month, MONTHS_AGO) do |date|
      @current_facility
        .patient_follow_ups(:month, date)
        .merge(BloodPressure.under_control)
        .count
    end
  end

  def monthly_registrations
    fetch_for_date(:month, MONTHS_AGO) do |date|
      @current_facility
        .registered_patients
        .where(recorded_at: date.all_month)
        .group(:gender)
        .count
    end
  end

  def all_time_follow_ups
    @current_facility
      .all_follow_ups
      .group(:gender)
      .count
  end

  def all_time_registrations
    @current_facility
      .registered_patients
      .group(:gender)
      .count
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
