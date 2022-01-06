# frozen_string_literal: true

class Api::V3::PatientPhoneNumberTransformer
  class << self
    def to_response(phone_number)
      response = Api::V3::Transformer
        .to_response(phone_number)
        .except("patient_id", "dnd_status")

      # TODO: Forcing phone_type to send `mobile` instead of `invalid`. Remove when client supports `invalid`
      unless ["mobile", "landline"].include?(response["phone_type"])
        response["phone_type"] = "mobile"
      end

      response
    end

    def from_request(phone_number)
      Api::V3::Transformer
        .from_request(phone_number)
        .except("dnd_status", "phone_type")
    end
  end
end
