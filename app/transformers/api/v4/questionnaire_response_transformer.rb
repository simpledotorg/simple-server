class Api::V4::QuestionnaireResponseTransformer < Api::V4::Transformer
  class << self
    def to_response(questionnaire_response)
      super.merge(questionnaire_type: questionnaire_response.questionnaire.questionnaire_type)
    end

    def from_request(payload_attributes)
      rename_attributes(payload_attributes, from_request_key_mapping).except(:questionnaire_type)
    end
  end
end
