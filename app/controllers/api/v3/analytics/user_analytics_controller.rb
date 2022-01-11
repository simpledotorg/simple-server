class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include SetForEndOfMonth
  before_action :set_for_end_of_month
  before_action :set_bust_cache

  layout false

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @period = Period.month(@for_end_of_month)
    if current_user.feature_enabled?(:follow_ups_v2)
      @range = Range.new(@period.advance(months: -5), @period)
      @repo = Reports::Repository.new(current_facility, periods: @range, follow_ups_v2: current_user.feature_enabled?(:follow_ups_v2))
      @query = Reports::FacilityStateGroup.where(facility_region_id: current_facility.region.id)
    end

    respond_to_html_or_json(@user_analytics.statistics)
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end

  def set_bust_cache
    RequestStore.store[:bust_cache] = true if params[:bust_cache].present?
  end
end
