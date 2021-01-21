class MyFacilities::DrugStocksController < AdminController
  include Pagination
  include MyFacilitiesFiltering

  layout "my_facilities"

  before_action :authorize_my_facilities
  after_action :verify_authorization_attempted
  before_action :set_facility, only: [:new, :create]
  before_action :set_for_end_of_month, only: [:new, :create]
  before_action :drug_stocks_enabled?

  def index
    @facilities = filter_facilities()
                    .includes(facility_group: :protocol_drugs)
                    .where(protocol_drugs: { stock_tracked: true })
  end

  def new
    drug_stock_list = DrugStock.select("DISTINCT ON (protocol_drug_id) *")
                               .where(facility_id: @facility.id, for_end_of_month: @for_end_of_month)
                               .order(:protocol_drug_id, created_at: :desc)
    @drug_stocks = drug_stock_list.inject({}) { |acc, drug_stock|
      acc[drug_stock.protocol_drug.id] = drug_stock
      acc
    }
  end

  def create
    drug_stocks = DrugStock.transaction do
      drug_stocks_reported.map do |drug_stock|
        DrugStock.create(facility: @facility,
                         user: current_admin,
                         protocol_drug_id: drug_stock[:protocol_drug_id],
                         received: drug_stock[:received].presence,
                         in_stock: drug_stock[:in_stock].presence,
                         for_end_of_month: @for_end_of_month)
      end
    end

    case
    when drug_stocks.empty?
      redirect_to my_facilities_drug_stocks_path
    when drug_stocks.all?(&:valid?)
      redirect_to my_facilities_drug_stocks_path, notice: "Saved drug stocks"
    when drug_stocks.any?(&:invalid?)
      redirect_to my_facilities_drug_stocks_path, alert: "Something went wrong, Drug Stocks were not saved."
    end
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
    @facility = current_admin.accessible_facilities(:view_reports).find_by_id(params[:facility_id])
  end

  def drug_stocks_params
    params.permit(:for_end_of_month, drug_stocks: [:received, :in_stock, :protocol_drug_id])
  end

  def drug_stocks_enabled?
    unless current_admin.feature_enabled?(:drug_stocks)
      redirect_to :root
    end
  end

  def set_for_end_of_month
    @for_end_of_month ||= Date.strptime(params[:for_end_of_month], "%B %Y").end_of_month
  end
end
