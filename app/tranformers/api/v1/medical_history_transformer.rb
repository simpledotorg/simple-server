class Api::V1::MedicalHistoryTransformer
  MEDICAL_HISTORY_QUESTIONS = [
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :diabetes,
    :diagnosed_with_hypertension
  ].freeze

  MEDICAL_HISTORY_ANSWERS_MAP = {
    yes: true,
    no: false,
    unknown: false
  }.with_indifferent_access.freeze

  INVERTED_MEDICAL_HISTORY_ANSWERS_MAP = {
    true => :yes,
    false => :no
  }.with_indifferent_access.freeze

  class << self
    def medical_history_questions
      MEDICAL_HISTORY_QUESTIONS
    end

    def to_response(medical_history)
      medical_history_attributes = medical_history.attributes.with_indifferent_access
      updates = MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, MEDICAL_HISTORY_ANSWERS_MAP[medical_history_attributes[key]]] }.to_h
      Api::Current::Transformer.to_response(medical_history).merge(updates)
    end

    def from_request(params)
      updates = MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, INVERTED_MEDICAL_HISTORY_ANSWERS_MAP[params[key]]] }.to_h
      Api::Current::Transformer.from_request(params).merge(updates)
    end
  end
end