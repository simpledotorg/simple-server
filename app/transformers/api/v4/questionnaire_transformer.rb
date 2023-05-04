class Api::V4::QuestionnaireTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire)
      questionnaire
        .as_json
        .except(
          "dsl_version",
          "is_active",
          "metadata",
          "created_at",
          "updated_at"
        )
        .merge("layout" => questionnaire.localized_layout)
    end
  end
end
