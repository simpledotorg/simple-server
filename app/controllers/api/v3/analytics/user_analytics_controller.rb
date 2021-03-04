class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper
  before_action :set_for_end_of_month

  layout false

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility, with_exclusions: report_with_exclusions?)

    @protocol_drugs = @current_facility.protocol.protocol_drugs.where(stock_tracked: true).sort_by(&:sort_key)
    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(current_facility, @for_end_of_month)

    respond_to_html_or_json(@user_analytics.statistics)
  end

  helper_method :current_facility, :current_user

  private

  def report_with_exclusions?
    current_user.feature_enabled?(:report_with_exclusions)
  end

  def respond_to_html_or_json(stats)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: stats }
    end
  end

  def set_for_end_of_month
    @for_end_of_month ||= if params[:for_end_of_month]
      Date.strptime(params[:for_end_of_month], "%b-%Y").end_of_month
    else
      Date.today.end_of_month
    end
  end
end
