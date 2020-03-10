class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  include ApplicationHelper
  include DashboardHelper
  include DayHelper
  include PeriodHelper

  layout false

  def show
    @days_ago = 30
    @daily_period_list = period_list(:day, @days_ago).sort.reverse.map { |date| doy_to_date_obj(*date) }

    @statistics = {
      daily: prepare_daily_stats(@days_ago),
      trophies: prepare_trophies,
      monthly: {},
      last_updated_at: Time.current,
      formatted_tomorrow_date: display_date(Time.current + 1.day),
      formatted_today_string: t(:today_str)
    }

    respond_to_html_or_json(@statistics)
  end

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end

  def follow_ups_for_last_n_days(n)
    follow_ups =
      MyFacilities::FollowUpsQuery
        .new(facilities: current_facility, period: :day, last_n: n)
        .follow_ups
        .group(:year, :day)
        .count
        .map { |date, fps| [doy_to_date_obj(*date), follow_ups: fps] }
        .to_h

    data_for_unavailable_dates(:follow_ups, @daily_period_list).merge(follow_ups)
  end

  def registrations_for_last_n_days(n)
    registrations =
      MyFacilities::RegistrationsQuery
        .new(facilities: current_facility, period: :day, last_n: n)
        .registrations
        .group_by { |reg| [reg.year, reg.day] }
        .map { |date, reg| [doy_to_date_obj(*date), registrations: reg.first.registration_count] }
        .to_h

    data_for_unavailable_dates(:registrations, @daily_period_list).merge(registrations)
  end

  def prepare_daily_stats(days_ago)
    [registrations_for_last_n_days(days_ago), follow_ups_for_last_n_days(days_ago)].inject(&:deep_merge)
  end

  TROPHY_MILESTONES =
    [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  POST_SEED_MILESTONE_INCR = 10_000

  def prepare_trophies
    total_follow_ups = MyFacilities::FollowUpsQuery.total_follow_ups(current_facility).count

    all_trophies =
      total_follow_ups > TROPHY_MILESTONES.last ?
        [*TROPHY_MILESTONES,
         *(POST_SEED_MILESTONE_INCR..(total_follow_ups + POST_SEED_MILESTONE_INCR)).step(POST_SEED_MILESTONE_INCR)] :
        TROPHY_MILESTONES

    unlocked_trophies_until = all_trophies.index { |v| total_follow_ups < v }

    { locked_trophy_value: all_trophies[unlocked_trophies_until],
      unlocked_trophy_values: all_trophies[0, unlocked_trophies_until] }
  end

  def data_for_unavailable_dates(data_key, period_list)
    period_list.map { |date| [date, data_key => 0] }.to_h
  end
end
