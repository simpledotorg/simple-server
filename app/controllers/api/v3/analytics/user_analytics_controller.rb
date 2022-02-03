class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include SetForEndOfMonth
  before_action :set_for_end_of_month
  before_action :set_bust_cache

  layout false

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @period = Period.month(@for_end_of_month)
    if current_user.feature_enabled?(:follow_ups_v2_progress_tab)
      @range = Range.new(@period.advance(months: -5), @period)
      @total_counts = Reports::FacilityStateGroup.totals(current_facility)
      @monthly_counts = Reports::FacilityStateGroup.where(facility_region_id: current_facility.region.id, month_date: @range).to_a
    end

    respond_to_html_or_json(@user_analytics.statistics)
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def respond_to_html_or_json(stats)
    respond_to do |format|
      if Flipper.enabled?(:new_progress_tab)
        format.html { render :show_v2 }
      else
        format.html { render :show }
      end
      format.json { render json: stats }
    end
  end

  def set_bust_cache
    RequestStore.store[:bust_cache] = true if params[:bust_cache].present?
  end
end
