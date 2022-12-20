class Api::V4::QuestionnaireTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire)
      questionnaire
        .except("dsl_version")
        .merge(
          "layout" => questionnaire.localized_layout,
          "created_at" => questionnaire.questionnaire_version.created_at
        )
    end
  end
end
