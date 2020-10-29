class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  skip_before_action :current_user_present?,
    :validate_sync_approval_status_allowed,
    :authenticate,
    :validate_facility,
    :validate_current_facility_belongs_to_users_facility_group

  layout false

  def show
    current_facility = Facility.first
    @current_facility = Facility.first
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
