class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  include SetForEndOfMonth
  before_action :set_for_end_of_month
  before_action :set_bust_cache

  layout false

  def show
    @period = Period.month(Date.current)
    @user_analytics = UserAnalyticsPresenter.new(current_facility)
    @service = Reports::FacilityProgressService.new(current_facility, @period)

    @total_follow_ups_dimension = Reports::FacilityProgressDimension.new(:follow_ups, diagnosis: :all, gender: :all)
    @total_registrations_dimension = Reports::FacilityProgressDimension.new(:registrations, diagnosis: :all, gender: :all)
    @total_follow_ups = Reports::MonthlyProgressComponent.new(@total_follow_ups_dimension, service: @service).total_count
    @total_registrations = Reports::MonthlyProgressComponent.new(@total_registrations_dimension, service: @service).total_count

    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)
    unless @drug_stocks.empty?
      @drug_stocks_query = DrugStocksQuery.new(facilities: [current_facility],
        for_end_of_month: @for_end_of_month)
      @drugs_by_category = @drug_stocks_query.protocol_drugs_by_category
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
