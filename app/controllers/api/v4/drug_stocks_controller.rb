class Api::V4::DrugStocksController < APIController
  def index
    if for_end_of_month.nil?
      render status: 400, json: {errors: ["valid `date` must be provided - eg. 2021-10-29"]}
      return
    end

    @drug_stocks = DrugStock.latest_for_facilities([current_facility], for_end_of_month)

    if @drug_stocks.empty?
      head :not_found
      return
    end
  end

  private

  def for_end_of_month
    @for_end_of_month ||= Date.parse(params[:date]).end_of_month
  rescue Date::Error, TypeError
    nil
  end
end
