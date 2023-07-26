class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include SetForEndOfMonth
  before_action :set_for_end_of_month
  before_action :set_bust_cache

  layout false

  def show
    @current_user = current_user
    @region = current_facility
    @period = Period.month(Date.current)
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @service = Reports::FacilityProgressService.new(current_facility, @period, current_user: @current_user)

    @is_diabetes_enabled = current_facility.diabetes_enabled?

    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)
    unless @drug_stocks.empty?
      @drug_stocks_query = DrugStocksQuery.new(facilities: [current_facility],
        for_end_of_month: @for_end_of_month)
      @drugs_by_category = @drug_stocks_query.protocol_drugs_by_category
    end

    respond_to do |format|
      format.html
      format.json { render json: @user_analytics.statistics }
    end
  end

  helper_method :current_facility, :current_user, :current_facility_group

  private

  def set_bust_cache
    RequestStore.store[:bust_cache] = true if params[:bust_cache].present?
  end
end
