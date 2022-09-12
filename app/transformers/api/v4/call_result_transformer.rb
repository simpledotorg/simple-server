class Api::V4::CallResultTransformer < Api::V4::Transformer
  class << self
    def from_request(call_result_payload, fallback_facility_id: nil)
      super(call_result_payload)
        .then { |attributes| add_fallback_patient_id(attributes) }
        .then { |attributes| add_fallback_facility_id(attributes, fallback_facility_id) }
    end

    private

    def add_fallback_patient_id(attributes)
      return attributes if attributes["patient_id"].present?

      appointment = Appointment.find_by(id: attributes["appointment_id"])
      attributes.merge("patient_id" => appointment&.patient_id)
    end

    def add_fallback_facility_id(attributes, facility_id)
      return attributes if attributes["facility_id"].present? || facility_id.blank?

      attributes.merge("facility_id" => facility_id)
    end
  end
end
