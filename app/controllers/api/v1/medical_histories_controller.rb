class Api::V1::MedicalHistoriesController < Api::V1::SyncController
  def sync_from_user
    __sync_from_user__(medical_histories_params)
  end

  def sync_to_user
    __sync_to_user__('medical_histories')
  end

  private

  def merge_if_valid(medical_history_params)
    validator = Api::V1::MedicalHistoryPayloadValidator.new(medical_history_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/MedicalHistory/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      medical_history = MedicalHistory.merge(Api::V1::Transformer.from_request(medical_history_params))
      { record: medical_history }
    end
  end

  def find_records_to_sync(since, limit)
    MedicalHistory.updated_on_server_since(since, limit)
  end

  def transform_to_response(medical_history)
    Api::V1::Transformer.to_response(medical_history)
  end

  def medical_histories_params
    params.require(:medical_histories).map do |medical_history_params|
      medical_history_params.permit(
        :id,
        :patient_id,
        :has_prior_heart_attack,
        :has_prior_stroke,
        :has_chronic_kidney_disease,
        :is_on_treatment_for_hypertension)
    end
  end
end
