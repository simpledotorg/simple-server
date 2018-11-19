class Api::V1::MedicalHistoriesController < Api::Current::MedicalHistoriesController
  def sync_from_user
    Raven.capture_message(
      'User is trying to sync medical histories using API V1.',
      user: current_user.id
    )
    __sync_from_user__(medical_histories_params)
  end

  private

  def transform_to_response(medical_history)
    Api::V1::MedicalHistoryTransformer.to_response(medical_history)
  end

  def merge_if_valid(medical_history_params)
    validator = Api::V1::MedicalHistoryPayloadValidator.new(medical_history_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?

    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/MedicalHistory/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      medical_history = MedicalHistory.merge(Api::V1::MedicalHistoryTransformer.from_request(medical_history_params))
      { record: medical_history }
    end
  end
end