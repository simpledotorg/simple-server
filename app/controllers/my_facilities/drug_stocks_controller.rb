class MyFacilities::DrugStocksController < AdminController
  include Pagination
  include MyFacilitiesFiltering
  include SetForEndOfMonth

  layout "my_facilities"

  around_action :set_reporting_time_zone
  before_action :authorize_my_facilities
  after_action :verify_authorization_attempted
  before_action :set_region_type, only: [:new, :create]
  before_action :set_region, only: [:new, :create]
  before_action :set_for_end_of_month
  before_action :redirect_unless_drug_stocks_enabled

  def drug_stocks
    create_drug_report
    @report = @query.drug_stocks_report

    respond_to do |format|
      format.html { render :drug_stocks }
      format.csv do
        send_data DrugStocksReportExporter.csv(@query), filename: "drug-stocks-report-#{@for_end_of_month_display}.csv"
      end
    end
  end

  def drug_consumption
    create_drug_report
    @report = @query.drug_consumption_report

    respond_to do |format|
      format.html { render :drug_consumption }
      format.csv do
        send_data DrugConsumptionReportExporter.csv(@query), filename: "drug-consumption-report-#{@for_end_of_month_display}.csv"
      end
    end
  end

  def new
    session[:report_url_with_filters] ||= request.referer
    @drug_stocks = DrugStock.latest_for_regions_grouped_by_protocol_drug(@region, @for_end_of_month)
  end

  def create
    DrugStocksCreator.call(user: current_admin,
      for_end_of_month: @for_end_of_month,
      drug_stocks_params: drug_stocks_params[:drug_stocks],
      region: @region)
    redirect_to redirect_url, notice: "Saved drug stocks"
  rescue ActiveRecord::RecordInvalid
    redirect_to redirect_url, alert: "Something went wrong, Drug Stocks were not saved."
  end

  private

  def create_drug_report
    @facilities = drug_stock_enabled_facilities
    @for_end_of_month_display = @for_end_of_month.strftime("%b-%Y")
    @query = DrugStocksQuery.new(facilities: @facilities,
      for_end_of_month: @for_end_of_month)
    @blocks = blocks_to_display
    @district_region = @query.facility_group.region
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

  def set_region_type
    @region_type = params[:region_type]
  end

  def set_region
    @region =
      case @region_type
      when "facility"
        authorize { current_admin.accessible_facility_regions(:manage).find_by_id(params[:region_id]) }
      when "district"
        authorize { current_admin.accessible_district_regions(:manage).find_by_id(params[:region_id]) }
      end
  end

  def blocks_to_display
    if @selected_facility_sizes == @facility_sizes && @selected_zones == @zones
      @query.blocks.order(:name)
    else
      Region.none
    end
  end

  def drug_stocks_params
    params.permit(
      :for_end_of_month,
      :region_type,
      drug_stocks:
        [:received,
          :in_stock,
          :redistributed,
          :protocol_drug_id]
    )
  end

  def redirect_unless_drug_stocks_enabled
    redirect_to :root unless current_admin.drug_stocks_enabled?
  end

  def drug_stock_enabled_facilities
    filter_facilities
      .includes(facility_group: :protocol_drugs)
      .where(protocol_drugs: {stock_tracked: true})
  end
end
