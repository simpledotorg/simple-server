class Api::V4::QuestionnaireResponsesController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("questionnaire_responses")
  end

  def sync_from_user
    __sync_from_user__(questionnaire_responses_params)
  end

  def current_facility_records
    @current_facility_records ||=
      QuestionnaireResponse
        .for_sync
        .where(facility_id: current_facility)
        .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    []
  end

  private

  def transform_to_response(questionnaire)
    Api::V4::QuestionnaireResponseTransformer.to_response(questionnaire)
  end

  def response_process_token
    {
      current_facility_id: current_facility.id,
      current_facility_processed_since: processed_until(current_facility_records) || current_facility_processed_since,
      resync_token: resync_token
    }
  end

  def force_resync?
    resync_token_modified?
  end

  def questionnaire_responses_params
    params.require(:questionnaire_responses).map do |questionnaire_response_params|
      questionnaire_response_params.permit(
        :id,
        :questionnaire_id,
        :facility_id,
        :user_id,
        :content,
        :created_at,
        :updated_at,
        :deleted_at
      )
    end
  end

  def merge_if_valid(questionnaire_response_params)
    validator = Api::V4::QuestionnaireResponsePayloadValidator.new(questionnaire_response_params)
    logger.debug "Questionnaire response payload had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.check_invalid?
      {errors_hash: validator.errors_hash}
    else
      transformed_params = Api::V4::QuestionnaireResponseTransformer.from_request(questionnaire_response_params)
      # merge transformed_params into DB
      {record: QuestionnaireResponse.merge_with_content(transformed_params)}
    end
  end
end
