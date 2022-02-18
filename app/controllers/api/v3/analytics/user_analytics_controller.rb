class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include SetForEndOfMonth
  before_action :set_for_end_of_month
  before_action :set_bust_cache

  layout false

  def show
    @period = Period.month(Date.current)
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @achievements = Reports::FacilityProgressAchievementService.new(current_facility)
    @service = Reports::FacilityProgressService.new(current_facility, @period)
    if Flipper.enabled?(:new_progress_tab)
      @data = Reports::ReportsFakeFacilityProgressService.new.call
    end

    respond_to do |format|
      if Flipper.enabled?(:new_progress_tab)
        format.html { render :show_v2 }
      else
        format.html { render :show }
      end
      format.json { render json: @user_analytics.statistics }
    end
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def set_bust_cache
    RequestStore.store[:bust_cache] = true if params[:bust_cache].present?
  end
end
