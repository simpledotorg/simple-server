# frozen_string_literal: true

class Api::V3::MedicalHistoryTransformer
  class << self
    def to_response(medical_history)
      Api::V3::Transformer
        .to_response(medical_history)
        .except("user_id")
        .except(*MedicalHistory::MEDICAL_HISTORY_QUESTIONS.map { |question| "#{question}_boolean" })
    end

    def from_request(medical_history_payload)
      Api::V3::Transformer.from_request(medical_history_payload).tap do |params|
        if params[:hypertension].blank?
          params[:hypertension] = "yes"
          params[:diagnosed_with_hypertension] = "yes"
        end
      end
    end
  end
end
