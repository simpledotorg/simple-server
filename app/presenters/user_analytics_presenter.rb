class UserAnalyticsPresenter
  include ApplicationHelper
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
            is_diabetes_enabled: @current_facility.diabetes_enabled?,
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

  def daily_stats
    follow_ups =
      @current_facility
        .patient_follow_ups(:day, last: DAYS_AGO)
        .count

    registrations =
      @current_facility
        .registered_patients
        .group_by_period(:day, :recorded_at, last: DAYS_AGO)
        .count

    {
      grouped_by_date:
        {
          follow_ups: follow_ups,
          registrations: registrations
        }
    }
  end

  def monthly_stats
    [monthly_unique_stats,
     monthly_htn_stats,
     monthly_dm_stats].inject(:deep_merge)
  end

  def all_time_stats
    [all_time_unique_stats,
     all_time_htn_stats,
     all_time_dm_stats].inject(:deep_merge)
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
    follow_ups =
      all_time_htn_stats.dig(:grouped_by_gender, :hypertension, :follow_ups).values.sum

    all_trophies = if follow_ups > TROPHY_MILESTONES.last
      [*TROPHY_MILESTONES, *(TROPHY_MILESTONE_INCR..(follow_ups + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)]
    else
      TROPHY_MILESTONES
    end

    unlocked_trophies_until = all_trophies.index { |v| follow_ups < v }

    {
      locked_trophy_value:
        all_trophies[unlocked_trophies_until],

      unlocked_trophy_values:
        all_trophies[0, unlocked_trophies_until]
    }
  end

  def monthly_unique_stats
    follow_ups =
      @current_facility
        .patient_follow_ups(:month, last: MONTHS_AGO)
        .count

    registrations =
      @current_facility
        .registered_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .count

    {
      grouped_by_date: {
        unique_total: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def monthly_htn_stats
    follow_ups =
      @current_facility
        .hypertension_follow_ups(:month, last: MONTHS_AGO)
        .group(:gender)
        .count

    controlled_visits =
      @current_facility
        .hypertension_follow_ups(:month, last: MONTHS_AGO)
        .merge(BloodPressure.under_control)
        .count

    registrations =
      @current_facility
        .registered_hypertension_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .group(:gender)
        .count

    {
      grouped_by_gender_and_date: {
        hypertension: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      },

      grouped_by_date: {
        hypertension: {
          follow_ups: sum_by_date(follow_ups),
          controlled_visits: controlled_visits,
          registrations: sum_by_date(registrations)
        }
      }
    }
  end

  def monthly_dm_stats
    follow_ups =
      @current_facility
        .diabetes_follow_ups(:month, last: MONTHS_AGO)
        .group(:gender)
        .count

    registrations =
      @current_facility
        .registered_diabetes_patients
        .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
        .group(:gender)
        .count

    {
      grouped_by_gender_and_date: {
        diabetes: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      },

      grouped_by_date: {
        diabetes: {
          follow_ups: sum_by_date(follow_ups),
          registrations: sum_by_date(registrations)
        }
      },
    }
  end

  def all_time_unique_stats
    follow_ups =
      @current_facility
        .hypertension_follow_ups(:month)
        .count
        .values
        .sum

    registrations =
      @current_facility
        .registered_hypertension_patients
        .count

    {
      grouped_by_date: {
        unique_total: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def all_time_htn_stats
    follow_ups =
      sum_by_gender(@current_facility
                      .hypertension_follow_ups(:month)
                      .group(:gender)
                      .count)

    registrations =
      @current_facility
        .registered_hypertension_patients
        .group(:gender)
        .count

    {
      grouped_by_gender: {
        hypertension: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def all_time_dm_stats
    follow_ups =
      sum_by_gender(@current_facility
                      .diabetes_follow_ups(:month)
                      .group(:gender)
                      .count)

    registrations =
      @current_facility
        .registered_diabetes_patients
        .group(:gender)
        .count

    {
      grouped_by_gender: {
        diabetes: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def statistics_cache_key
    "user_analytics/#{@current_facility.id}"
  end

  def sum_by_date(data)
    data.each_with_object({}) do |((date, _), count), by_date|
      by_date[date] ||= 0
      by_date[date] += count
    end
  end

  def sum_by_gender(data)
    data.each_with_object({}) do |((_, gender), count), by_gender|
      by_gender[gender] ||= 0
      by_gender[gender] += count
    end
  end
end
