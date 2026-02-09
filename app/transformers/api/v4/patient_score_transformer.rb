class Api::V4::PatientScoreTransformer < Api::V4::Transformer
  class << self
    def to_response(payload)
      super(payload)
        .merge({
          "score_type" => payload["score_type"],
          "score_value" => payload["score_value"].to_f
        })
    end

    def from_request(payload)
      super(payload)
        .merge({
          "score_type" => payload["score_type"],
          "score_value" => payload["score_value"].to_f
        })
    end
  end
end
