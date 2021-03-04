class DrugStocksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_for_end_of_month
  layout false

  def create
    @facility = Facility.find(drug_stocks_params[:facility_id])
    authenticate

    DrugStock.transaction do
      drug_stocks_params[:drug_stocks].map do |drug_stock|
        DrugStock.create!(facility: @facility,
                          user: current_user,
                          protocol_drug_id: drug_stock[:protocol_drug_id],
                          received: drug_stock[:received].presence,
                          in_stock: drug_stock[:in_stock].presence,
                          for_end_of_month: @for_end_of_month)
      end
    end
    redirect_to drug_stocks_url(for_end_of_month: @for_end_of_month,
                                facility_id: @facility.id,
                                user_id: current_user.id,
                                auth_token: current_user.access_token)
  rescue ActiveRecord::RecordInvalid => e
    logger.error "could not create DrugStocks - record invalid", errors: e.message
    render json: {status: "invalid", errors: e.message}, status: 422
  end

  def index
    @facility = Facility.find(drug_stocks_params[:facility_id])
    authenticate
    @protocol_drugs = @facility.protocol.protocol_drugs.where(stock_tracked: true).sort_by(&:sort_key)
    drug_stock_list = DrugStock.latest_for_facility(@facility, @for_end_of_month) || []
    @drug_stocks = drug_stock_list.each_with_object({}) { |drug_stock, acc|
      acc[drug_stock.protocol_drug.id] = drug_stock
    }
  end

  private

  def auth_token
    @auth_token ||= drug_stocks_params[:auth_token]
  end

  def current_user
    @current_user ||= User.find(drug_stocks_params[:user_id])
  end

  def fail_request(status, reason)
    logger.warn "API request failed due to #{reason}"
    head(status)
  end

  def authenticate
    return fail_request(:unauthorized, "access_token unauthorized") unless access_token_authorized?
    RequestStore.store[:current_user_id] = current_user.id
    current_user.mark_as_logged_in if current_user.has_never_logged_in?
  end

  def access_token_authorized?
    ActiveSupport::SecurityUtils.secure_compare(auth_token, current_user.access_token)
  end

  def drug_stocks_params
    params.permit(
      :auth_token,
      :facility_id,
      :user_id,
      :for_end_of_month,
      drug_stocks:
        [:received,
          :in_stock,
          :protocol_drug_id]
    )
  end

  def set_for_end_of_month
    @for_end_of_month ||= if params[:for_end_of_month]
      Date.parse(params[:for_end_of_month]).end_of_month
    else
      Date.today.end_of_month
    end
  end
end
