# This emulates what progress tab shows in the API, but does it within our dashboard.
# The main purpose currently is to make it easier to develop on progress tab in dev.
class Reports::ProgressController < AdminController
  layout false
  before_action :require_feature_flag
  before_action :set_period
  before_action :find_region

  def show
    @current_user = current_user
    @current_facility = @region
    @user_analytics = UserAnalyticsPresenter.new(@region)
    @service = Reports::FacilityProgressService.new(current_facility, @period)

    @total_follow_ups_dimension = Reports::FacilityProgressDimension.new(:follow_ups, diagnosis: :all, gender: :all)
    @total_registrations_dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :all, gender: :all)
    @total_follow_ups = Reports::MonthlyProgressComponent.new(@total_follow_ups_dimension, service: @service, current_user: @current_user).total_count
    @total_registrations = Reports::MonthlyProgressComponent.new(@total_registrations_dimension, service: @service, current_user: @current_user).total_count
    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)

    @is_diabetes_enabled = current_facility.diabetes_enabled?

    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)
    unless @drug_stocks.empty?
      @drug_stocks_query = DrugStocksQuery.new(facilities: [current_facility],
        for_end_of_month: @for_end_of_month)
      @drugs_by_category = @drug_stocks_query.protocol_drugs_by_category
    end

    @period_reports_data = Reports::ReportsFakeFacilityProgressService.new(@current_facility.name).period_reports
    @hypertension_reports_data = Reports::ReportsFakeFacilityProgressService.new(@current_facility.name).hypertension_reports
    @diabetes_reports_data = Reports::ReportsFakeFacilityProgressService.new(@current_facility.name).diabetes_reports

    if Flipper.enabled?(:new_progress_tab_v2, @current_user) || Flipper.enabled?(:new_progress_tab_v2)
      render "api/v3/analytics/user_analytics/show_v2"
    elsif Flipper.enabled?(:new_progress_tab_v1, @current_user) || Flipper.enabled?(:new_progress_tab_v1)
      render "api/v3/analytics/user_analytics/show_v1"
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
