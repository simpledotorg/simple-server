class Api::V4::QuestionnaireResponseTransformer < Api::V4::Transformer
  class << self
    def from_request(payload_attributes)
      rename_attributes(payload_attributes, from_request_key_mapping)
    end
  end
end
