# frozen_string_literal: true

class Api::V3::PrescriptionDrugTransformer
  class << self
    def to_response(prescription_drug)
      Api::V3::Transformer.to_response(prescription_drug).except("user_id")
    end

    def from_request(prescription_drug_payload)
      Api::V3::Transformer.from_request(prescription_drug_payload)
    end
  end
end
