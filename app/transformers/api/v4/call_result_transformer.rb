class Api::V4::CallResultTransformer < Api::V4::Transformer
  class << self
    def from_request(call_result_payload, fallback_facility_id: nil)
      super(call_result_payload)
        .then { |payload| add_fallback_patient_id(payload) }
        .then { |payload| add_fallback_facility_id(payload, fallback_facility_id) }
    end

    private

    def add_fallback_patient_id(payload)
      return payload if payload["patient_id"].present?

      appointment = Appointment.find_by(id: payload["appointment_id"])
      payload.merge("patient_id" => appointment&.patient_id)
    end

    def add_fallback_facility_id(payload, facility_id)
      return payload if payload["facility_id"].present? || facility_id.blank?

      payload.merge("facility_id" => facility_id)
    end
  end
end
