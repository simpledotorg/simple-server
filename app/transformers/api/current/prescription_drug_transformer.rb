class Api::Current::PrescriptionDrugTransformer
  class << self
    def to_response(prescription_drug)
      Api::Current::Transformer.to_response(prescription_drug).except('user_id')
    end

    def from_request(prescription_drug_payload)
      Api::Current::Transformer.from_request(prescription_drug_payload)
    end
  end
end