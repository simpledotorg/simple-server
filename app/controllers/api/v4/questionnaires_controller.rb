class Api::V4::QuestionnairesController < Api::V4::SyncController
  def sync_to_user
    __sync_to_user__("questionnaires")
  end

  def transform_to_response(questionnaire)
    Api::V4::QuestionnaireTransformer.to_response(questionnaire)
  end

  def current_facility_records
    # TODO: Current implementation always responds with 1 JSON minimum. Reason:
    # process_token.last_updated_at has precision upto 3 milliseconds & is always lesser than updated_at.
    Questionnaire
      .for_sync
      .where(dsl_version: params.require("dsl_version").to_i)
      .updated_on_server_since(current_facility_processed_since, limit)
  end

  def other_facility_records
    []
  end

  private

  def locale_modified?
    process_token[:locale] != I18n.locale.to_s
  end

  def force_resync?
    locale_modified? || resync_token_modified?
  end

  def current_facility_processed_since
    return Time.new(0) if force_resync?
    process_token[:current_facility_processed_since].try(:to_time) || Time.new(0)
  end

  def response_process_token
    {
      current_facility_processed_since: processed_until(current_facility_records) || current_facility_processed_since,
      locale: I18n.locale.to_s,
      resync_token: resync_token
    }
  end
end
