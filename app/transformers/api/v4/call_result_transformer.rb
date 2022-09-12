class Api::V4::CallResultTransformer < Api::V4::Transformer
  class << self
    def from_request(call_result_payload)
      attributes = super(call_result_payload)
      return attributes if attributes["patient_id"].present?

      appointment = Appointment.find_by(id: call_result_payload["appointment_id"])
      attributes.merge("patient_id" => appointment&.patient_id)
    end
  end
end
