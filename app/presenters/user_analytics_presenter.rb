class UserAnalyticsPresenter
  include ApplicationHelper
  include DayHelper
  include PeriodHelper
  include DashboardHelper
  include ActionView::Helpers::NumberHelper
  include BustCache

  def initialize(current_facility)
    @current_facility = current_facility
  end

  attr_reader :current_facility

  DAYS_AGO = 30
  MONTHS_AGO = 6
  HTN_CONTROL_MONTHS_AGO = 12
  TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  TROPHY_MILESTONE_INCR = 10_000
  CACHE_VERSION = 4
  EXPIRE_STATISTICS_CACHE_IN = 15.minutes

  def daily_stats_by_date(*stats)
    zero_if_blank_or_zero statistics.dig(:daily, :grouped_by_date, *stats)
  end

  def monthly_htn_stats_by_date(*stats)
    zero_if_blank_or_zero statistics.dig(:monthly, :grouped_by_date, :hypertension, *stats)
  end

  def monthly_dm_stats_by_date(*stats)
    zero_if_blank_or_zero statistics.dig(:monthly, :grouped_by_date, :diabetes, *stats)
  end

  def monthly_htn_or_dm_stats_by_date(*stats)
    zero_if_blank_or_zero statistics.dig(:monthly, :grouped_by_date, :htn_or_dm, *stats)
  end

  def monthly_htn_control_rate(month_date)
    monthly_htn_stats_by_date(:controlled_visits, :controlled_patients_rate, Period.month(month_date)).round
  end

  def monthly_htn_control_last_period
    htn_control_monthly_period_list.last.to_s(:month_year)
  end

  def monthly_htn_control_last_period_patient_counts
    controlled_patients = monthly_htn_stats_by_date(
      :controlled_visits,
      :controlled_patients,
      Period.month(htn_control_monthly_period_list.last)
    )
    registrations = monthly_htn_stats_by_date(
      :controlled_visits,
      :adjusted_patient_counts,
      Period.month(htn_control_monthly_period_list.last)
    )

    numerator = number_with_delimiter(controlled_patients)
    denominator = number_with_delimiter(registrations)
    unit = "patient".pluralize(registrations)
    "#{numerator} of #{denominator} #{unit}"
  end

  def monthly_htn_control_last_control_rate
    monthly_htn_control_rate(htn_control_monthly_period_list.last)
  end

  def monthly_dm_stats_by_date_and_gender(stat, month_date, gender)
    zero_if_blank_or_zero statistics.dig(:monthly, :grouped_by_date_and_gender, :diabetes, stat, [month_date, gender])
  end

  def monthly_htn_stats_by_date_and_gender(stat, month_date, gender)
    zero_if_blank_or_zero statistics.dig(:monthly, :grouped_by_date_and_gender, :hypertension, stat, [month_date, gender])
  end

  def all_time_htn_or_dm_count(stat)
    zero_if_blank_or_zero statistics.dig(:all_time, :grouped_by_date, :htn_or_dm, stat)
  end

  def all_time_dm_count(stat)
    zero_if_blank_or_zero statistics.dig(:all_time, :grouped_by_gender, :diabetes, stat).values.sum
  end

  def all_time_htn_count(stat)
    zero_if_blank_or_zero statistics.dig(:all_time, :grouped_by_gender, :hypertension, stat).values.sum
  end

  def all_time_dm_stats_by_gender(stat, gender)
    zero_if_blank_or_zero statistics.dig(:all_time, :grouped_by_gender, :diabetes, stat, gender)
  end

  def all_time_htn_stats_by_gender(stat, gender)
    zero_if_blank_or_zero statistics.dig(:all_time, :grouped_by_gender, :hypertension, stat, gender)
  end

  def cohort_controlled(cohort)
    display_percentage(cohort[:controlled], cohort[:registered])
  end

  def cohort_uncontrolled(cohort)
    display_percentage(cohort[:uncontrolled], cohort[:registered])
  end

  def cohort_no_bp(cohort)
    display_percentage(cohort[:no_bp], cohort[:registered])
  end

  def locked_trophy
    statistics.dig(:trophies, :locked_trophy_value)
  end

  def unlocked_trophies
    statistics.dig(:trophies, :unlocked_trophy_values)
  end

  def achievements?
    statistics.dig(:trophies, :locked_trophy_value) > TROPHY_MILESTONES.first
  end

  def diabetes_enabled?
    current_facility.diabetes_enabled?
  end

  def daily_period_list
    period_list_as_dates(:day, DAYS_AGO)
  end

  def monthly_period_list
    period_list_as_dates(:month, MONTHS_AGO)
  end

  def htn_control_monthly_period_list
    period_list_as_dates(:month, HTN_CONTROL_MONTHS_AGO + 1).reverse.tap(&:pop)
  end

  def display_percentage(numerator, denominator)
    return "0%" if denominator.nil? || denominator.zero? || numerator.nil?
    percentage = (numerator * 100.0) / denominator

    "#{percentage.round(0)}%"
  end

  def last_updated_at
    statistics.dig(:metadata, :last_updated_at)
  end

  def statistics
    @statistics ||=
      Rails.cache.fetch(statistics_cache_key, expires_in: EXPIRE_STATISTICS_CACHE_IN, force: bust_cache?) {
        {
          daily: daily_stats,
          monthly: monthly_stats,
          all_time: all_time_stats,
          cohorts: cohort_stats,
          trophies: trophy_stats,
          metadata: {
            is_diabetes_enabled: diabetes_enabled?,
            last_updated_at: I18n.l(Time.current),
            formatted_next_date: display_date(Time.current + 1.day),
            today_string: I18n.t(:today_str)
          }
        }
      }
  end

  private

  def daily_stats
    diabetes_enabled? ? daily_htn_or_dm_stats : daily_htn_stats
  end

  def daily_htn_stats
    activity = ActivityService.new(current_facility, period: :day, last: DAYS_AGO)

    {
      grouped_by_date: {
        follow_ups: activity.follow_ups,
        registrations: activity.registrations
      }
    }
  end

  def daily_htn_or_dm_stats
    activity = ActivityService.new(current_facility, diagnosis: :all, period: :day, last: DAYS_AGO)

    {
      grouped_by_date: {
        follow_ups: activity.follow_ups,
        registrations: activity.registrations
      }
    }
  end

  def monthly_stats
    return monthly_htn_stats unless diabetes_enabled?

    [monthly_htn_or_dm_stats,
      monthly_htn_stats,
      monthly_dm_stats].inject(:deep_merge)
  end

  def controlled_stats(range)
    repo = Reports::Repository.new(current_facility.region, periods: range)
    slug = current_facility.region.slug
    {
      adjusted_patient_counts: repo.adjusted_patients_without_ltfu[slug],
      controlled_patients: repo.controlled[slug],
      controlled_patients_rate: repo.controlled_rates[slug]
    }
  end

  def all_time_stats
    return all_time_htn_stats unless diabetes_enabled?

    [all_time_htn_or_dm_stats,
      all_time_htn_stats,
      all_time_dm_stats].inject(:deep_merge)
  end

  def cohort_stats
    periods = Period.quarter(Date.current).previous.downto(3)
    CohortService.new(region: current_facility, periods: periods).call
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
    follow_up_count = all_time_htn_stats.dig(:grouped_by_gender, :hypertension, :follow_ups).values.sum
    milestones = trophy_milestones(follow_up_count)
    locked_milestone_idx = milestones.index { |milestone| follow_up_count < milestone }

    {
      locked_trophy_value:
        milestones[locked_milestone_idx],

      unlocked_trophy_values:
        milestones[0, locked_milestone_idx]
    }
  end

  def trophy_milestones(follow_up_count)
    if follow_up_count >= TROPHY_MILESTONES.last
      [*TROPHY_MILESTONES,
        *(TROPHY_MILESTONE_INCR..(follow_up_count + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)]
    else
      TROPHY_MILESTONES
    end
  end

  def monthly_htn_or_dm_stats
    activity = ActivityService.new(current_facility, diagnosis: :all, last: MONTHS_AGO)

    {
      grouped_by_date: {
        htn_or_dm: {
          follow_ups: activity.follow_ups,
          registrations: activity.registrations
        }
      }
    }
  end

  def monthly_htn_stats
    activity_by_gender = ActivityService.new(current_facility, group: :gender, last: MONTHS_AGO)
    activity = ActivityService.new(current_facility, last: MONTHS_AGO)

    control_rate_end = Period.month(Date.current.advance(months: -1).beginning_of_month)
    control_rate_start = control_rate_end.advance(months: -HTN_CONTROL_MONTHS_AGO)
    range = (control_rate_start..control_rate_end)

    {
      grouped_by_date_and_gender: {
        hypertension: {
          registrations: activity_by_gender.registrations,
          follow_ups: activity_by_gender.follow_ups
        }
      },

      grouped_by_date: {
        hypertension: {
          registrations: activity.registrations,
          follow_ups: activity.follow_ups,
          controlled_visits: controlled_stats(range)
        }
      }
    }
  end

  def monthly_dm_stats
    activity_by_gender = ActivityService.new(current_facility, diagnosis: :diabetes, group: :gender, last: MONTHS_AGO)
    activity = ActivityService.new(current_facility, diagnosis: :diabetes, last: MONTHS_AGO)

    {
      grouped_by_date_and_gender: {
        diabetes: {
          follow_ups: activity_by_gender.follow_ups,
          registrations: activity_by_gender.registrations
        }
      },

      grouped_by_date: {
        diabetes: {
          follow_ups: activity.follow_ups,
          registrations: activity.registrations
        }
      }
    }
  end

  def all_time_htn_or_dm_stats
    activity_by_gender = ActivityService.new(current_facility, diagnosis: :all, group: :gender)
    follow_ups = activity_by_gender.follow_ups.values.sum
    registrations = activity_by_gender.registrations.values.sum

    {
      grouped_by_date: {
        htn_or_dm: {
          follow_ups: follow_ups,
          registrations: registrations
        }
      }
    }
  end

  def all_time_htn_stats
    activity_by_gender = ActivityService.new(current_facility, group: :gender)
    follow_ups = sum_by_gender(activity_by_gender.follow_ups)
    registrations = sum_by_gender(activity_by_gender.registrations)

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
    activity_by_gender = ActivityService.new(current_facility, diagnosis: :diabetes, group: :gender)
    follow_ups = sum_by_gender(activity_by_gender.follow_ups)
    registrations = sum_by_gender(activity_by_gender.registrations)

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
    v2 = Reports.reporting_schema_v2?
    "user_analytics/#{current_facility.id}/dm=#{diabetes_enabled?}/v2=#{v2}/#{CACHE_VERSION}"
  end

  def sum_by_gender(data)
    data.each_with_object({}) do |((_, gender), count), by_gender|
      by_gender[gender] ||= 0
      by_gender[gender] += count
    end
  end
end
