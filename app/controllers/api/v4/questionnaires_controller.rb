class Api::V4::QuestionnairesController < Api::V4::SyncController
  private def records_to_sync
    Questionnaire.take(1)
  end

  def sync_to_user
    __sync_to_user__("questionnnaires")
  end

  def transform_to_response(questionnaire)
    Api::V3::QuestionnaireTransformer.to_response(questionnaire)
  end
end
