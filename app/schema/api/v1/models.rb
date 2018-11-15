class Api::V1::Models < Api::Current::Models
  class << self
    def medical_history
      { type: :object,
        properties: {
          id: { '$ref' => '#/definitions/uuid' },
          patient_id: { '$ref' => '#/definitions/uuid' },
          prior_heart_attack: { type: :boolean },
          prior_stroke: { type: :boolean },
          chronic_kidney_disease: { type: :boolean },
          receiving_treatment_for_hypertension: { type: :boolean },
          diabetes: { type: :boolean },
          diagnosed_with_hypertension: { type: :boolean },
          created_at: { '$ref' => '#/definitions/timestamp' },
          updated_at: { '$ref' => '#/definitions/timestamp' } },
        required: [
          :id,
          :patient_id,
          :prior_heart_attack,
          :prior_stroke,
          :chronic_kidney_disease,
          :receiving_treatment_for_hypertension,
          :diabetes,
          :created_at,
          :updated_at
        ]
      }
    end

    def definitions
      Api::Current::Models.definitions.merge(medical_history: medical_history)
    end
  end
end