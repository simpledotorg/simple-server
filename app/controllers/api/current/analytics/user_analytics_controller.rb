class Api::Current::Analytics::UserAnalyticsController < Api::Current::AnalyticsController
  include DashboardHelper
  include DayHelper

  layout false

  def show
    @statistics = {
      overall_registrations_per_day: registrations_for_last_n_days(30),
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

  def registrations_for_last_n_days(n)
    MyFacilities::RegistrationsQuery
      .new(facilities: current_facility, period: :day, last_n: n)
      .registrations
  end
end
