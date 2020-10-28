class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper

  layout false

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    respond_to_html_or_json(@user_analytics.statistics)
  end

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end
end
