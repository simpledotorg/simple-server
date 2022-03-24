class Api::V4::DrugStocksController < APIController
  def index
    return head :bad_request if for_end_of_month.nil?

    drug_stocks = DrugStock.latest_for_facilities([current_facility], for_end_of_month)
    return head :not_found if drug_stocks.empty?

    render json: {
      month: for_end_of_month,
      facility_id: current_facility.id,
      drugs: drug_stocks.map do |stock|
        {
          protocol_drug_id: stock.protocol_drug_id,
          in_stock: stock.in_stock,
          received: stock.received
        }
      end
    }
  end

  private

  def for_end_of_month
    @for_end_of_month ||= Date.parse(params[:date]).end_of_month
  rescue Date::Error, TypeError
    nil
  end
end
