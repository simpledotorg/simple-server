class Api::Current::AppointmentTransformer
  class << self
    def to_response(appointment)
      Api::Current::Transformer.to_response(appointment).except('user_id')
    end

    def from_request(appointment_payload)
      Api::Current::Transformer.from_request(appointment_payload)
    end
  end
end