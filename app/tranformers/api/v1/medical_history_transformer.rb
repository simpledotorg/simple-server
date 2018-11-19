class Api::V1::MedicalHistoryTransformer
  MEDICAL_HISTORY_ANSWERS_MAP = {
    yes: true,
    no: false,
    unknown: false
  }.with_indifferent_access.freeze

  INVERTED_MEDICAL_HISTORY_ANSWERS_MAP = {
    true => :yes,
    false => :unknown
  }.with_indifferent_access.freeze

  class << self
    def from_request(params)
      updates = MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, INVERTED_MEDICAL_HISTORY_ANSWERS_MAP[params[key]]] }.to_h
      Api::Current::Transformer.from_request(params).merge(updates)
    end

    def to_response(medical_history)
      medical_history_attributes = medical_history.attributes.with_indifferent_access
      updates = MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |key| [key.to_s, MEDICAL_HISTORY_ANSWERS_MAP[medical_history_attributes[key]]] }.to_h
      Api::Current::Transformer
        .to_response(medical_history)
        .merge(updates)
        .except(*MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |question| "#{question}_boolean" })
    end
  end
end