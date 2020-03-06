class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  include DashboardHelper
  include DayHelper

  layout false

  def show
    @statistics = {
      daily: prepare_daily_stats,
      trophies: prepare_trophies,
      monthly: {},
      last_updated_at: Time.current
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
    MyFacilities::FollowUpsQuery
      .new(facilities: current_facility, period: :day, last_n: n)
      .follow_ups
      .group(:year, :day)
      .count
      .map { |date, follow_ups| [doy_to_date_obj(*date), follow_ups: follow_ups] }
      .to_h
  end

  def registrations_for_last_n_days(n)
    MyFacilities::RegistrationsQuery
      .new(facilities: current_facility, period: :day, last_n: n)
      .registrations
      .group_by { |reg| [reg.year, reg.day] }
      .map { |date, reg| [doy_to_date_obj(*date), registrations: reg.first.registration_count] }
      .to_h
  end

  def prepare_daily_stats
    [registrations_for_last_n_days(30), follow_ups_for_last_n_days(30)].inject(&:deep_merge)
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
end
