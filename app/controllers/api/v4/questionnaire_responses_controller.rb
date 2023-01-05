class Api::V4::QuestionnaireResponsesController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("questionnaire_responses")
  end

  def current_facility_records
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
      other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
      resync_token: resync_token
    }
  end

  def force_resync?
    resync_token_modified?
  end
end
