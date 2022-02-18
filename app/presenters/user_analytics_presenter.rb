class UserAnalyticsPresenter
  include ApplicationHelper
  include DayHelper
  include PeriodHelper
  include DashboardHelper
  include ActionView::Helpers::NumberHelper
  include BustCache

  def initialize(current_facility)
    @current_facility = current_facility.source
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
          cohorts: cohort_stats,
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
    "user_analytics/#{current_facility.id}/dm=#{diabetes_enabled?}/#{CACHE_VERSION}"
  end

  def sum_by_gender(data)
    data.each_with_object({}) do |((_, gender), count), by_gender|
      by_gender[gender] ||= 0
      by_gender[gender] += count
    end
  end
end
