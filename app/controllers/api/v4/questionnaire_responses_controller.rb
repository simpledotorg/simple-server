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
end
