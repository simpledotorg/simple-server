class Api::V4::QuestionnaireTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire)
      super(questionnaire)
        .merge("layout" => questionnaire.localized_layout)
    end
  end
end
