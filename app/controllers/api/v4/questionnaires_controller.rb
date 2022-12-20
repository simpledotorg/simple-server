class Api::V4::QuestionnairesController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("questionnnaires")
  end

  def transform_to_response(questionnaire)
    Api::V4::QuestionnaireTransformer.to_response(questionnaire)
  end

  def current_facility_records
    []
  end

  def other_facility_records
    # TODO: Current implementation always responds with 1 JSON minimum. Reason:
    # process_token.last_updated_at has precision upto 3 milliseconds & is always lesser than updated_at.
    Questionnaire
      .for_sync
      .where(dsl_version: params.require("dsl_version").to_i)
      .updated_on_server_since(other_facilities_processed_since, limit)
  end

  private

  def locale_modified?
    process_token[:locale] != I18n.locale.to_s
  end

  def force_resync?
    locale_modified? || resync_token_modified?
  end

  def response_process_token
    {other_facilities_processed_since: processed_until(other_facility_records) || other_facilities_processed_since,
     locale: I18n.locale,
     resync_token: resync_token}
  end
end
