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
    @facilities = filter_facilities
                    .includes(facility_group: :protocol_drugs)
                    .where(protocol_drugs: { stock_tracked: true })

    render and return if @facilities.empty?
    # handle no facilities
    for_end_of_month = Date.strptime("January 2021", "%B %Y").end_of_month
    patient_counts = Patient.where(assigned_facility: @facilities.map(&:id)).group(:assigned_facility).count
    latest_drug_stocks = DrugStock.latest_for_facilities(@facilities, for_end_of_month)
    # assuming that all facilities on the page have the same protocol
    # report = ReportObject.new(facilities, for_end_of_month, patient_counts latest_drug_stocks)
    protocol = @facilities.first.protocol
    drug_categories = protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
    report = patient_counts.each_with_object({}) do |(facility, patient_count), report|
      report[facility.id] = {}
      report[facility.id][:patient_count] = patient_count
      next if latest_drug_stocks[facility.id].nil?
      drug_categories.each do |(drug_category, protocol_drugs)|
        drug_stocks = latest_drug_stocks[facility.id].select { |drug_stock| drug_stock.protocol_drug.drug_category == drug_category }
        report[facility.id][drug_category] = {
          ## key this by name
          drug_stocks: drug_stocks,
          patient_days: patient_days(facility, drug_category, protocol_drugs, key_by_rxnorm(drug_stocks), patient_count)
        }
      end
    end
  end

  def key_by_rxnorm(latest_drug_stocks)
    latest_drug_stocks.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.rxnorm_code] = drug_stock
    }
  end

  def patient_days(facility, drug_category, protocol_drugs, drug_stocks, patient_count)
    begin
      coefficients = patient_days_coefficients[facility.state]
      numerator = protocol_drugs.map(&:rxnorm_code).map { |rxnorm_code|
        drug_stocks[rxnorm_code].in_stock * coefficients[:drug_categories][drug_category][rxnorm_code]
      }.reduce(:+)
      denominator = patient_count * coefficients[:load_factor] * coefficients[:drug_categories][drug_category][:new_patient_coefficient]
      (numerator / denominator).floor
    rescue
      # either drug stock is nil, or drug is not in formula
      :error
    end
  end

  def patient_days_coefficients
    { "Karnataka":
        { load_factor: 1,
          drug_categories:
            { "hypertension_ccb":
                { new_patient_coefficient: 1.4,
                  "329528": 1,
                  "329526": 2 },
              "hypertension_arb":
                { new_patient_coefficient: 0.37,
                  "316764": 1,
                  "316765": 2,
                  "979467": 1 },
              "hypertension_diuretic":
                { new_patient_coefficient: 0.06,
                  "316049": 1,
                  "331132": 1 }, }
        }
    }.with_indifferent_access
  end

  def new
    session[:report_url_with_filters] ||= request.referer
    drug_stock_list = DrugStock.latest_for_facility(@facility, @for_end_of_month)
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
    @for_end_of_month ||= Date.strptime(params[:for_end_of_month], "%B %Y").end_of_month
  end
end
