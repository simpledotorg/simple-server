class Api::Current::MedicalHistoryTransformer
  class << self
    def to_response(medical_history)
      Api::Current::Transformer
        .to_response(medical_history)
        .except('user_id')
        .except(*MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |question| "#{question}_boolean" })
    end

    def from_request(medical_history_payload)
      Api::Current::Transformer.from_request(medical_history_payload)
    end
  end
end