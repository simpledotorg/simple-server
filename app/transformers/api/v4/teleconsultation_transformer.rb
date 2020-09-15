class Api::V4::TeleconsultationTransformer
  class << self
    def to_response(teleconsultation)
      Api::V4::Transformer.to_response(teleconsultation)
        .except(teleconsultation.request.keys)
        .except(teleconsultation.record.keys)
        .merge({"request" => teleconsultation.request,
                "record" => teleconsultation.record})
    end

    def from_request(teleconsultation)
      request, record = teleconsultation["request"], teleconsultation["record"]

      payload = Api::V4::Transformer.from_request(teleconsultation).except("request", "record")
      payload.merge!(request) if request
      payload.merge!(record) if record
    end
  end
end
