class UserAnalyticsPresenter < Struct.new(:current_facility)
  include Memoized
  include ApplicationHelper
  include DayHelper
  include PeriodHelper
  include DashboardHelper

  DAYS_AGO = 30
  MONTHS_AGO = 6
  TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  TROPHY_MILESTONE_INCR = 10_000

  def daily_stats_by_date(stat, day_date)
    display_stat(stat,
                 registrations: daily_regs.dig(day_date),
                 follow_ups: daily_follow_ups.dig(day_date))
  end

  def monthly_htn_stats_by_date(stat, month_date)
    display_stat(stat,
                 registrations: monthly_htn_regs.dig(month_date),
                 follow_ups: monthly_htn_follow_ups.dig(month_date),
                 controlled_visits: monthly_htn_controlled_visits.dig(month_date))
  end

  def monthly_dm_stats_by_date(stat, month_date)
    display_stat(stat,
                 registrations: monthly_dm_regs.dig(month_date),
                 follow_ups: monthly_dm_follow_ups.dig(month_date))
  end

  def monthly_htn_or_dm_stats_by_date(stat, month_date)
    display_stat(stat,
                 registrations: monthly_htn_or_dm_regs.dig(month_date),
                 follow_ups: monthly_htn_or_dm_follow_ups.dig(month_date))
  end

  def monthly_htn_control_rate_by_date(month_date)
    display_percentage(monthly_htn_stats_by_date(:controlled_visits, month_date),
                       monthly_htn_stats_by_date(:follow_ups, month_date))
  end

  def monthly_dm_stats_with_gender(stat, month_date, gender)
    display_stat(stat,
                 registrations: monthly_dm_regs_with_gender.dig([month_date, gender]),
                 follow_ups: monthly_dm_follow_ups_with_gender.dig([month_date, gender]))
  end

  def monthly_htn_stats_with_gender(stat, month_date, gender)
    display_stat(stat,
                 registrations: monthly_htn_regs_with_gender.dig([month_date, gender]),
                 follow_ups: monthly_htn_follow_ups_with_gender.dig([month_date, gender]))
  end

  def all_time_htn_or_dm_count(stat)
    display_stat(stat,
                 registrations: all_time_htn_or_dm_regs,
                 follow_ups: all_time_htn_or_dm_follow_ups)
  end

  def all_time_dm_count(stat)
    display_stat(stat,
                 registrations: all_time_dm_regs_with_gender.values.sum,
                 follow_ups: all_time_dm_follow_ups_with_gender.values.sum)
  end

  def all_time_htn_count(stat)
    display_stat(stat,
                 registrations: all_time_htn_regs_with_gender.values.sum,
                 follow_ups: all_time_htn_follow_ups_with_gender.values.sum)
  end

  def all_time_dm_stats_with_gender(stat, gender)
    display_stat(stat,
                 registrations: all_time_dm_regs_with_gender.dig(gender),
                 follow_ups: all_time_dm_follow_ups_with_gender.dig(gender))
  end

  def all_time_htn_stats_with_gender(stat, gender)
    display_stat(stat,
                 registrations: all_time_htn_regs_with_gender.dig(gender),
                 follow_ups: all_time_htn_follow_ups_with_gender.dig(gender))
  end

  def achievements?
    achievements.dig(:locked_trophy_value) > TROPHY_MILESTONES.first
  end

  def locked_trophy
    achievements.dig(:locked_trophy_value)
  end

  def unlocked_trophies
    achievements.dig(:unlocked_trophy_values)
  end

  def daily_period_list
    period_list_as_dates(:day, DAYS_AGO)
  end

  def monthly_period_list
    period_list_as_dates(:month, MONTHS_AGO)
  end

  def last_updated_at
    I18n.l(Time.current)
  end

  def diabetes_enabled?
    FeatureToggle.enabled?('DIABETES_SUPPORT_IN_PROGRESS_TAB') && current_facility.diabetes_enabled?
  end

  def js_payload
    {
      dates_for_daily_stats: daily_regs.keys | daily_follow_ups.keys,
      formatted_next_date: display_date(Time.current + 1.day),
      today_string: I18n.t(:today_str)
    }
  end

  private

  def display_percentage(numerator, denominator)
    return '0%' if denominator.nil? || denominator.zero? || numerator.nil?
    percentage = (numerator * 100.0) / denominator

    "#{percentage.round(0)}%"
  end

  memoize def daily_regs
    if diabetes_enabled?
      current_facility
        .registered_patients
        .group_by_period(:day, :recorded_at, last: DAYS_AGO)
        .count
    else
      current_facility
        .registered_hypertension_patients
        .group_by_period(:day, :recorded_at, last: DAYS_AGO)
        .count
    end
  end

  memoize def daily_follow_ups
    if diabetes_enabled?
      current_facility
        .patient_follow_ups_by_period(:day, last: DAYS_AGO)
        .count
    else
      current_facility
        .hypertension_follow_ups_by_period(:day, last: DAYS_AGO)
        .count
    end
  end

  memoize def monthly_htn_or_dm_regs
    current_facility
      .registered_patients
      .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
      .count
  end

  memoize def monthly_htn_or_dm_follow_ups
    current_facility
      .patient_follow_ups_by_period(:month, last: MONTHS_AGO)
      .count
  end

  memoize def monthly_htn_regs_with_gender
    current_facility
      .registered_hypertension_patients
      .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
      .group(:gender)
      .count
  end

  memoize def monthly_htn_regs
    sum_by_date(monthly_htn_regs_with_gender)
  end

  memoize def monthly_htn_follow_ups_with_gender
    current_facility
      .hypertension_follow_ups_by_period(:month, last: MONTHS_AGO)
      .group(:gender)
      .count
  end

  memoize def monthly_htn_follow_ups
    sum_by_date(monthly_htn_follow_ups_with_gender)
  end

  memoize def monthly_htn_controlled_visits
    current_facility
      .hypertension_follow_ups_by_period(:month, last: MONTHS_AGO)
      .merge(BloodPressure.under_control)
      .count
  end

  memoize def monthly_dm_regs_with_gender
    current_facility
      .registered_diabetes_patients
      .group_by_period(:month, :recorded_at, last: MONTHS_AGO)
      .group(:gender)
      .count
  end

  memoize def monthly_dm_regs
    sum_by_date(monthly_dm_regs_with_gender)
  end

  memoize def monthly_dm_follow_ups_with_gender
    current_facility
      .diabetes_follow_ups_by_period(:month, last: MONTHS_AGO)
      .group(:gender)
      .count
  end

  memoize def monthly_dm_follow_ups
    sum_by_date(monthly_dm_follow_ups_with_gender)
  end

  memoize def all_time_htn_or_dm_follow_ups
    current_facility
      .patient_follow_ups_by_period(:month)
      .count
      .values
      .sum
  end

  memoize def all_time_htn_or_dm_regs
    current_facility
      .registered_patients
      .count
  end

  memoize def all_time_htn_regs_with_gender
    current_facility
      .registered_hypertension_patients
      .group(:gender)
      .count
  end

  memoize def all_time_htn_follow_ups_with_gender
    sum_by_gender(current_facility
                    .hypertension_follow_ups_by_period(:month)
                    .group(:gender)
                    .count)
  end

  memoize def all_time_dm_regs_with_gender
    current_facility
      .registered_diabetes_patients
      .group(:gender)
      .count
  end

  memoize def all_time_dm_follow_ups_with_gender
    sum_by_gender(current_facility
                    .diabetes_follow_ups_by_period(:month)
                    .group(:gender)
                    .count)
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
  memoize def achievements
    follow_ups = all_time_htn_follow_ups_with_gender.values.sum

    all_trophies = if follow_ups > TROPHY_MILESTONES.last
                     [*TROPHY_MILESTONES,
                      *(TROPHY_MILESTONE_INCR..(follow_ups + TROPHY_MILESTONE_INCR)).step(TROPHY_MILESTONE_INCR)]
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

  def display_stat(stat_name, stats)
    zero_if_unavailable(stats[stat_name])
  end
end
