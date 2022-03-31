class Api::V4::DrugStocksController < APIController
  def index
    if for_end_of_month.nil?
      render status: 400, json: {errors: ["valid `date` must be provided in YYYY-MM-DD format - eg. 2021-10-29"]}
      return
    end

    @drug_stocks = DrugStock.latest_for_facilities([current_facility], for_end_of_month)

    head :not_found if @drug_stocks.empty?
  end

  private

  def for_end_of_month
    @for_end_of_month ||= Date.strptime(params[:date], "%Y-%m-%d").end_of_month
  rescue ArgumentError, TypeError
    nil
  end
end
