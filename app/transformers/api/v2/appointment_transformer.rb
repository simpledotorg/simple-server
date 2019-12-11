class Api::V2::AppointmentTransformer < Api::Current::AppointmentTransformer
  class << self
    def to_response(appointment)
      super.except('appointment_type', 'creation_facility_id')
    end

    def from_request(appointment_payload)
      super.except('appointment_type')
    end
  end
end
