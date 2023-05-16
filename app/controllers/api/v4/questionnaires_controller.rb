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
    dsl_version = params.require("dsl_version")
    dsl_version_major = dsl_version.split(".")[0]

    # For dsl_version "1.5", return all questionnaires from "1" to "1.5".
    # De-duplicate multiple questionnaires of same type by choosing latest dsl_version.
    Questionnaire
      .for_sync
      .joins("
        INNER JOIN (
          SELECT questionnaire_type, max(dsl_version) max_version
          FROM questionnaires
          WHERE dsl_version BETWEEN '#{dsl_version_major}' AND '#{dsl_version}'
            AND is_active = TRUE
          GROUP BY questionnaire_type
        ) q
        ON q.max_version = questionnaires.dsl_version AND q.questionnaire_type = questionnaires.questionnaire_type")
      .where(dsl_version: dsl_version_major..dsl_version)
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
