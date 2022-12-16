class Api::V4::QuestionnaireTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire)
      super(questionnaire)
        .merge("blood_sugar_value" => blood_sugar["blood_sugar_value"].to_f)
    end
  end
end