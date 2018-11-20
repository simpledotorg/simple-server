class Api::Current::MedicalHistoryTransformer
  class << self
    def to_response(medical_history)
      Api::Current::Transformer
        .to_response(medical_history)
        .except(*MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |question| "#{question}_boolean" })
    end
  end
end