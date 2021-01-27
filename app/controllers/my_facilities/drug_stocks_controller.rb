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
    protocol = @facilities.first.protocol
    drug_categories = protocol.protocol_drugs.where(stock_tracked: true).group_by(&:drug_category)
    report = patient_counts.each_with_object({}) { |(facility, patient_count), report|
      report[facility.id] = {}
      report[facility.id][:patient_count] = patient_count
      next if latest_drug_stocks[facility.id].nil?
      drug_categories.each do |drug_category|
        report[facility.id][drug_category] = {
          ## key this by name
          latest_drug_stocks: latest_drug_stocks[facility.id].select { |drug_stock| drug_stock[:drug_category] },
          patient_days: patient_days(latest_drug_stocks[facility.id], patient_count)
        }
      end
    }
  end

  def patient_days(latest_drug_stocks, patient_count)
    100
  end

  def rxnorm_codes
    {
      "amLODIPine 5mg": "329528",
      "amlo 10": "329526",
      "telmi 40": "316764",
      "telmi 80": "316765",
      "losartan 50": "979467",
      "chlorthalidone 12.5": "331132",
      "chlorthalidone 25": "315655"
    }

    ProtocolDrug.find("ea1377c3-5c9b-42eb-8087-ad99cd80ce5a").update(stock_tracked: true, rxnorm_code: "329528", drug_category: "hypertension_ccb")
    ProtocolDrug.find("b57bb05b-992f-4376-b353-9df56c2224c9").update(stock_tracked: true, rxnorm_code: "329526", drug_category: "hypertension_ccb")
    ProtocolDrug.find("2c2b870f-eb1d-41f7-b803-4b5ae5b64e25").update(stock_tracked: true, rxnorm_code: "316764", drug_category: "hypertension_arb")
    ProtocolDrug.find("0588c3c3-007f-4725-9def-60d49fd379ca").update(stock_tracked: true, rxnorm_code: "316765", drug_category: "hypertension_arb")
    ProtocolDrug.find("893d2ee3-4a8a-45fd-9213-4d25788c556d").update(stock_tracked: true, rxnorm_code: "979467", drug_category: "hypertension_arb")
    ProtocolDrug.find("4bf6e927-7c04-478f-95f8-22602a8adb20").update(stock_tracked: true, rxnorm_code: "331132", drug_category: "hypertension_diuretic")
    ProtocolDrug.find("7ffcc130-88af-4290-a770-6b9ebe5eddfc").update(stock_tracked: true, rxnorm_code: "315655", drug_category: "hypertension_diuretic")
  end

  def patient_days_coefficients
    { "Punjab":
        { load_factor: 1,
          drug_categories:
            { "hypertension_ccb":
                { new_patient_coefficient: 1.4,
                },
              "hypertension_arb": {},
              "hypertension_diuretic": {} }
        }
    }
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
