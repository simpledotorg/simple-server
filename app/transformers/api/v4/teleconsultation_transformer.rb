class Api::V4::TeleconsultationTransformer
  class << self
    def from_request(teleconsultation, retrieve_record: false)
      request, record = teleconsultation["request"], teleconsultation["record"]
      payload = Api::V4::Transformer.from_request(teleconsultation).except("request", "record")

      payload.merge!(request) if request
      payload.merge!(record) if record && retrieve_record
      payload
    end
  end
end
