# frozen_string_literal: true

class Api::V3::AppointmentTransformer
  class << self
    def creation_facility_id(payload)
      payload[:creation_facility_id].blank? ? payload[:facility_id] : payload[:creation_facility_id]
    end

    def to_response(appointment)
      Api::V3::Transformer.to_response(appointment).except("user_id")
    end

    def from_request(appointment_payload)
      Api::V3::Transformer.from_request(appointment_payload
                                               .merge(creation_facility_id: creation_facility_id(appointment_payload)))
    end
  end
end
