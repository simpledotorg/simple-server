class Api::V3::Analytics::UserAnalyticsController < Api::V3::AnalyticsController
  include ApplicationHelper

  layout false

  def show
    @user_analytics = UserAnalyticsPresenter.new(current_facility, with_exclusions: report_with_exclusions?)

    @protocol_drugs = @current_facility.protocol.protocol_drugs.where(stock_tracked: true).sort_by(&:sort_key)
    drug_stock_list = DrugStock.latest_for_facility(@facility, @for_end_of_month) || []
    @drug_stocks = drug_stock_list.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }

    respond_to_html_or_json(@user_analytics.statistics)
  end

  def create
    redirect_to api_v3_analytics_user_analytics_path(format: "html"), notice: "ok!"
  end

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
end
