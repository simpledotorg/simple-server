class MyFacilities::DrugStocksController < AdminController
  include Pagination
  include MyFacilitiesFiltering

  layout "my_facilities"

  before_action :authorize_my_facilities
  after_action :verify_authorization_attempted
  before_action :set_facility, only: [:new, :create]
  before_action :set_for_end_of_month
  before_action :drug_stocks_enabled?
  before_action :set_force_cache, only: [:index]

  def index
    @facilities = filter_facilities
      .includes(facility_group: :protocol_drugs)
      .where(protocol_drugs: {stock_tracked: true})
    @for_end_of_month_display = @for_end_of_month.strftime("%b-%Y")
    render && return if @facilities.empty?
    query = DrugStocksQuery.new(facilities: @facilities, for_end_of_month: @for_end_of_month)
    @report = query.call
    @drugs_by_category = query.protocol_drugs_by_category
  end

  def new
    session[:report_url_with_filters] ||= request.referer
    drug_stock_list = DrugStock.latest_for_facility(@facility, @for_end_of_month) || []
    @drug_stocks = drug_stock_list.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end

  def create
    report_url_with_filters = session[:report_url_with_filters]
    session[:report_url_with_filters] = nil

    drug_stocks = DrugStock.transaction do
      drug_stocks_reported.map do |drug_stock|
        DrugStock.create!(facility: @facility,
                          user: current_admin,
                          protocol_drug_id: drug_stock[:protocol_drug_id],
                          received: drug_stock[:received].presence,
                          in_stock: drug_stock[:in_stock].presence,
                          for_end_of_month: @for_end_of_month)
      end
    end

    if drug_stocks.empty?
      redirect_to report_url_with_filters
    elsif drug_stocks.all?(&:valid?)
      redirect_to report_url_with_filters, notice: "Saved drug stocks"
    elsif drug_stocks.any?(&:invalid?)
      redirect_to report_url_with_filters, alert: "Something went wrong, Drug Stocks were not saved."
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to report_url_with_filters, alert: "Something went wrong, Drug Stocks were not saved."
  end

  private

  def drug_stocks_reported
    drug_stocks_params[:drug_stocks].reject do |drug_stock|
      drug_stock[:in_stock].blank? && drug_stock[:received].blank?
    end
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

  def set_for_end_of_month
    @for_end_of_month ||= if params[:for_end_of_month]
      Date.strptime(params[:for_end_of_month], "%b-%Y").end_of_month
    else
      Date.today.end_of_month
    end
  end
end
