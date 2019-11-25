class Api::Current::BloodSugarsController < Api::Current::SyncController
  include Api::Current::PrioritisableByFacility

  def sync_from_user
    __sync_from_user__(blood_sugars_params)
  end

  def sync_to_user
    __sync_to_user__('blood_sugars')

  end

  private

  def transform_to_response(blood_sugar)
    Api::Current::Transformer.to_response(blood_sugar)
  end

  def merge_if_valid(blood_sugar_params)
    validator = Api::Current::BloodSugarPayloadValidator.new(blood_sugar_params)
    logger.debug "Blood Sugar payload had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/BloodSugar/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      record_params = Api::Current::Transformer
                        .from_request(blood_sugar_params)

      blood_sugar = BloodSugar.merge(record_params)
      { record: blood_sugar }
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