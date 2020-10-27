class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper

  layout false

  skip_before_action :current_user_present?
  skip_before_action :validate_sync_approval_status_allowed
  skip_before_action :authenticate
  skip_before_action :validate_facility
  skip_before_action :validate_current_facility_belongs_to_users_facility_group

  def show
    current_facility = Facility.find_by(name: "DH Udaipur")
    @current_facility = Facility.find_by(name: "DH Udaipur")
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
