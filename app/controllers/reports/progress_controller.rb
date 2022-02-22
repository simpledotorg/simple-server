# This emulates what progress tab shows in the API, but does it within our dashboard.
# The main purpose currently is to make it easier to develop on progress tab in dev.
class Reports::ProgressController < AdminController

  layout false
  before_action :require_feature_flag
  before_action :set_period
  before_action :find_region

  def show
    @current_facility = @region
    @user_analytics = UserAnalyticsPresenter.new(@region)
    @service = Reports::FacilityProgressService.new(current_facility, @period)
    @achievements = Reports::FacilityProgressAchievementService.new(current_facility)

    if Flipper.enabled?(:new_progress_tab)
      @period_reports_data = Reports::ReportsFakeFacilityProgressService.new(@current_facility.name).period_reports
      @diagnosis_reports_data = Reports::ReportsFakeFacilityProgressService.new(@current_facility.name).diagnosis_reports
      @drug_stock_reports_data = Reports::ReportsFakeFacilityProgressService.new(@current_facility.name).drug_stock_reports
      render "api/v3/analytics/user_analytics/show_v2"
    else
      render "api/v3/analytics/user_analytics/show"
    end
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def current_facility
    @region.source
  end

  def current_user
    current_admin
  end

  def current_facility_group
    current_facility.facility_group
  end

  def require_feature_flag
    if !current_admin.feature_enabled?(:dashboard_progress_reports)
      user_not_authorized
      nil
    end
  end

  def find_region
    @region ||= authorize {
      current_admin.accessible_facility_regions(:view_reports).find_by!(slug: report_params[:id])
    }
  end

  def report_params
    params.permit(:id, :bust_cache, :v2, :report_scope, {period: [:type, :value]})
  end

  def set_period
    period_params = report_params[:period].presence || Reports.default_period.attributes
    @period = Period.new(period_params)
  end
end
