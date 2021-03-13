class MyFacilities::DrugStocksController < AdminController
  include Pagination
  include MyFacilitiesFiltering
  include SetForEndOfMonth

  layout "my_facilities"

  before_action :authorize_my_facilities
  after_action :verify_authorization_attempted
  before_action :set_facility, only: [:new, :create]
  before_action :set_for_end_of_month
  before_action :drug_stocks_enabled?
  before_action :set_bust_cache, only: [:drug_stocks, :drug_consumption]

  def drug_stocks
    drug_report
    @report = @query.drug_stocks_report
  end

  def drug_consumption
    drug_report
    @report = @query.drug_consumption_report
  end

  def new
    session[:report_url_with_filters] ||= request.referer
    @drug_stocks = DrugStock.latest_for_facilities_grouped_by_protocol_drug(@facility, @for_end_of_month)
  end

  def create
    DrugStocksCreator.call(current_admin, @facility, @for_end_of_month, drug_stocks_params[:drug_stocks])
    redirect_to redirect_url(bust_cache: true), notice: "Saved drug stocks"
  rescue ActiveRecord::RecordInvalid
    redirect_to redirect_url, alert: "Something went wrong, Drug Stocks were not saved."
  end

  private

  def drug_report
    @facilities = filter_facilities
      .includes(facility_group: :protocol_drugs)
      .where(protocol_drugs: {stock_tracked: true})
    @for_end_of_month_display = @for_end_of_month.strftime("%b-%Y")
    render && return if @facilities.empty?
    @query = DrugStocksQuery.new(facilities: @facilities, for_end_of_month: @for_end_of_month)
    @drugs_by_category = @query.protocol_drugs_by_category
  end

  def redirect_url(query_params = {})
    report_url_with_filters = session[:report_url_with_filters]
    session[:report_url_with_filters] = nil
    return report_url_with_filters if query_params.empty?
    url = Addressable::URI.parse(report_url_with_filters)
    url.query_values = (url.query_values || {}).merge(query_params.with_indifferent_access)
    url.to_s
  end

  def authorize_my_facilities
    authorize { current_admin.accessible_facilities(:view_reports).any? }
  end

  def set_facility
    @facility = authorize { current_admin.accessible_facilities(:manage).find_by_id(params[:facility_id]) }
  end

  def drug_stocks_params
    params.permit(
      :for_end_of_month,
      drug_stocks:
        [:received,
          :in_stock,
          :protocol_drug_id]
    )
  end

  def drug_stocks_enabled?
    unless current_admin.feature_enabled?(:drug_stocks)
      redirect_to :root
    end
  end
end
