class Reports::ProgressController < AdminController
  layout false
  before_action :set_period
  before_action :find_region

  def show
    d @region
    @user_analytics = UserAnalyticsPresenter.new(@region)
    @current_facility = @region
    d @user_analytics
    render "api/v3/analytics/user_analytics/show"
    # respond_to do |format|
    #   format.html { render "api/v3/analytics/user_analytics/show" }
      # format.json { render json: stats }
    # end

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

  def find_region
    d report_params[:id]
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
