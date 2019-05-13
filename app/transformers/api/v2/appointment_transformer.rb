class Api::V2::AppointmentTransformer < Api::Current::AppointmentTransformer
  class << self
    def to_response(appointment)
      Api::Current::Transformer.to_response(appointment).except('appointment_type')
    end

    def from_request(appointment_payload)
      Api::Current::Transformer.from_request(appointment_payload).except('appointment_type')
    end
  end
end
