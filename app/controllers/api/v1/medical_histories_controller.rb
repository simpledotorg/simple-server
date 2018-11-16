class Api::V1::MedicalHistoriesController < Api::Current::MedicalHistoriesController
  private

  def transform_to_response(medical_history)
    Api::V1::MedicalHistoryTransformer.to_response(medical_history)
  end

  def merge_if_valid(medical_history_params)
    existing_record = MedicalHistory.find_by(id: medical_history_params[:id])
    conflicts = existing_record.present? ? conflicts_with_existing_record(existing_record, medical_history_params) : {}

    validator = Api::V1::MedicalHistoryPayloadValidator.new(medical_history_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?

    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/MedicalHistory/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      medical_history = MedicalHistory.merge(Api::V1::MedicalHistoryTransformer.from_request(medical_history_params).merge(conflicts))
      { record: medical_history }
    end
  end

  def conflicts_with_existing_record(record, params)
    conflicts = {}
    MedicalHistory::MEDICAL_HISTORY_QUESTIONS.each do |question|
      if record.read_attribute(question) == 'unknown' && params[question] == false
        conflicts[question] = 'unknown'
      end
    end
    Raven.capture_message("[V1 Compatibilty Issue] User is trying to override unknown with false in medical history.", user: current_user.id, params: params.to_h) if conflicts.present?
    conflicts
  end
end