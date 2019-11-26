class Api::V2::AppointmentTransformer
  class << self
    def to_response(appointment)
      Api::Current::Transformer.to_response(appointment)
        .except('appointment_type', 'user_id', 'creation_facility_id')
    end

    def from_request(appointment_payload)
      Api::Current::Transformer.from_request(appointment_payload)
        .except('appointment_type', 'creation_facility_id')
    end
  end
end
