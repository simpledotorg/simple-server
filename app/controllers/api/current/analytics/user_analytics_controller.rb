class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  include DashboardHelper
  include DayHelper

  layout false

  TROPHIES_FOR_FOLLOW_UPS =
    [10, 25, 50, 100, 250, 500,
     1000, 2000, 3000, 4000, 5000,
     10000, 20000, 30000, 30000, 40000, 50000, 60000, 70000, 80000, 90000,
     100000]

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

  def prepare_trophies
    total_follow_ups = MyFacilities::FollowUpsQuery.total_follow_ups(current_facility).count
    unlocked_trophy_until = TROPHIES_FOR_FOLLOW_UPS.index { |v| total_follow_ups < v }

    { locked_trophy_value: TROPHIES_FOR_FOLLOW_UPS[unlocked_trophy_until],
      unlocked_trophy_values: TROPHIES_FOR_FOLLOW_UPS[0, unlocked_trophy_until] }
  end

  def doy_to_date_obj(year, day)
    Date.ordinal(year.to_i, day.to_i)
  end
end
