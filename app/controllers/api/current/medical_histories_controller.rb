class Api::Current::MedicalHistoriesController < Api::Current::SyncController
  def sync_from_user
    __sync_from_user__(medical_histories_params)
  end

  def sync_to_user
    __sync_to_user__('medical_histories')
  end

  private

  def current_facility_records
    MedicalHistory.where(patient: Patient.where(registration_facility: current_facility))
      .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    other_facilities_limit = limit - current_facility_records.count
    MedicalHistory.where(patient: Patient.where(registration_facility: current_user.facilities_in_group_other_than(current_facility)))
      .updated_on_server_since(other_facilities_processed_since, other_facilities_limit)
  end


  def merge_if_valid(medical_history_params)
    validator = Api::Current::MedicalHistoryPayloadValidator.new(medical_history_params)
    logger.debug "Follow Up Schedule had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      NewRelic::Agent.increment_metric('Merge/MedicalHistory/schema_invalid')
      { errors_hash: validator.errors_hash }
    else
      medical_history = MedicalHistory.merge(Api::Current::Transformer.from_request(medical_history_params))
      { record: medical_history }
    end
  end

  def transform_to_response(medical_history)
    Api::Current::MedicalHistoryTransformer.to_response(medical_history)
  end

  def medical_histories_params
    params.require(:medical_histories).map do |medical_history_params|
      medical_history_params.permit(
        :id,
        :patient_id,
        :prior_heart_attack,
        :prior_stroke,
        :chronic_kidney_disease,
        :receiving_treatment_for_hypertension,
        :diabetes,
        :diagnosed_with_hypertension,
        :created_at,
        :updated_at)
    end
  end
end
