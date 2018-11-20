class MedicalHistory < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true

  MEDICAL_HISTORY_QUESTIONS = [
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :diabetes,
    :diagnosed_with_hypertension
  ].freeze

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end
