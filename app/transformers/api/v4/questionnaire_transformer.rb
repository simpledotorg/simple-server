class Api::V4::QuestionnaireTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire)
      questionnaire
        .attributes
        .except(
          "dsl_version",
          "version_id",
          "updated_at"
        )
        .merge(
          "id" => questionnaire.version_id,
          "layout" => questionnaire.localized_layout,
        )
    end
  end
end
