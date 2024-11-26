class Api::V4::PatientAttributeTransformer < Api::V4::Transformer
  class << self
    def to_response(patient_attribute)
      super(patient_attribute)
    end

    def from_request(payload)
      super(payload).
        merge({
          "height" => payload["height"].to_f,
          "weight" => payload["weight"].to_f,
        })
    end
  end
end
