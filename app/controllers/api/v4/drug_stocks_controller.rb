class Api::V4::DrugStocksController < Api::V4::SyncController
  def show
    for_end_of_month = begin
      Date.parse(params[:date]).end_of_month
    rescue Date::Error, TypeError
      nil
    end

    if for_end_of_month.nil?
      head :bad_request
    else
      drug_stocks = DrugStock.latest_for_facilities([current_facility], for_end_of_month)

      if drug_stocks.empty?
        head :not_found
      else
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
    end

  end

  def sync_from_user
    __sync_from_user__(blood_sugars_params)
  end

  def sync_to_user
    __sync_to_user__("blood_sugars")
  end

  private

  def transform_to_response(blood_sugar)
    Api::V4::BloodSugarTransformer.to_response(blood_sugar)
  end

  def merge_if_valid(blood_sugar_params)
    validator = Api::V4::BloodSugarPayloadValidator.new(blood_sugar_params)
    logger.debug "Blood Sugar payload had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      set_patient_recorded_at(blood_sugar_params)
      transformed_params = Api::V4::Transformer.from_request(blood_sugar_params)
      {record: merge_encounter_observation(:blood_sugars, transformed_params)}
    end
  end

  def blood_sugars_params
    params.require(:blood_sugars).map do |blood_sugar_params|
      blood_sugar_params.permit(
        :id,
        :blood_sugar_type,
        :blood_sugar_value,
        :patient_id,
        :facility_id,
        :user_id,
        :created_at,
        :updated_at,
        :recorded_at,
        :deleted_at
      )
    end
  end
end
