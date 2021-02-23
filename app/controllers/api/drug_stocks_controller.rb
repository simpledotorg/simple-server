class Api::DrugStocksController < APIController
  before_action :set_for_end_of_month

  def create
    @facility = current_facility
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
    render json: { status: "OK" }
  rescue ActiveRecord::RecordInvalid
    redirect_to redirect_url, alert: "Something went wrong, Drug Stocks were not saved."
  end

  private

  def drug_stocks_params
    params.permit(
      :for_end_of_month,
      drug_stocks:
        [:received,
          :in_stock,
          :protocol_drug_id]
    )
  end

  def set_for_end_of_month
    @for_end_of_month ||= if params[:for_end_of_month]
      Date.strptime(params[:for_end_of_month], "%b-%Y").end_of_month
    else
      Date.today.end_of_month
    end
  end
end