class Api::V4::QuestionnaireTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire)
      {
        "id" => questionnaire.version_id,
        "type" => questionnaire.questionnaire_type,
        "layout" => questionnaire.localized_layout,
        "created_at" => questionnaire.questionnaire_version.created_at,
        "updated_at" => questionnaire.updated_at,
        "deleted_at" => questionnaire.deleted_at,
      }
    end
  end
end
