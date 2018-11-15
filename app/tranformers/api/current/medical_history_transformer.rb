class Api::Current::MedicalHistoryTransformer
  MEDICAL_HISTORY_QUESTIONS = [
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :diabetes,
    :diagnosed_with_hypertension
  ].freeze

  class << self
    def medical_history_questions
      MEDICAL_HISTORY_QUESTIONS
    end

    def to_response(medical_history)
      medical_history_attributes = medical_history.attributes.with_indifferent_access
      updates = MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, medical_history_attributes[key] || false] }.to_h
      Api::Current::Transformer.to_response(medical_history).merge(updates)
    end
  end
end