class Api::Current::MedicalHistoryTransformer
  class << self

    def to_response(medical_history)
      medical_history_attributes = medical_history.attributes.with_indifferent_access
      updates = MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, medical_history_attributes[key] || false] }.to_h
      Api::V1::Transformer.to_response(medical_history).merge(updates)
    end
  end
end