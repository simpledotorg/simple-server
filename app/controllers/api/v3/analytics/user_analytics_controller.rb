class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  layout false

  caches_action :show, cache_path: -> { cache_key }, expires_in: 15.minutes

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility)

    respond_to do |format|
      format.html { render :show }
    end
  end

  private

  def cache_key
    "user_analytics/#{current_facility.id}"
  end
end
