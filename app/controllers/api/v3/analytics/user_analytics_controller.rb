class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  layout false

  caches_action :show
  expire_action action: :show, expires_in: 15.minutes

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility)

    respond_to do |format|
      format.html { render :show }
    end
  end
end
