# frozen_string_literal: true

class Api::V3::PatientBusinessIdentifierTransformer
  class << self
    def to_response(business_identifier)
      Api::V3::Transformer
        .to_response(business_identifier)
        .except("patient_id")
        .merge(business_identifier.metadata.present? ? {"metadata" => business_identifier.metadata.to_json} : {})
    end

    def from_request(business_identifier)
      Api::V3::Transformer
        .from_request(business_identifier)
        .merge(business_identifier["metadata"].present? ? {"metadata" => JSON.parse(business_identifier["metadata"])} : {})
        .merge("identifier" => business_identifier["identifier"] || "")
    end
  end
end
