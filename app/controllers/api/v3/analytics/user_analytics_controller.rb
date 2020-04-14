class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include DashboardHelper

  layout false

  def show
    show_legacy and return unless FeatureToggle.enabled?('NEW_PROGRESS_TAB')

    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @statistics = @user_analytics.statistics
    respond_to_html_or_json(@statistics)
  end

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end

  def show_legacy
    @user_analytics = Legacy::UserAnalyticsPresenter.new(current_facility)
    return respond_to_html_or_json_legacy(nil) unless @user_analytics.first_patient_at_facility.present?

    @statistics = @user_analytics.statistics
    respond_to_html_or_json_legacy(@statistics)
  end

  def respond_to_html_or_json_legacy(stats)
    respond_to do |format|
      format.html { render 'api/v3/analytics/user_analytics/legacy/show' }
      format.json { render json: stats }
    end
  end
end
