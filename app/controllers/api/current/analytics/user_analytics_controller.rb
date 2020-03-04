class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  include DashboardHelper
  include DayHelper

  layout false

  def show
    @statistics = {
      daily: prepare_daily_stats,
      monthly: {},
      trophies: {},
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

  def doy_to_date_obj(year, day)
    Date.ordinal(year.to_i, day.to_i)
  end
end
