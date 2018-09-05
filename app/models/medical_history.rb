class MedicalHistory < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true

  validates :has_prior_heart_attack, inclusion: [true, false]
  validates :has_prior_stroke, inclusion: [true, false]
  validates :has_chronic_kidney_disease, inclusion: [true, false]
  validates :is_on_treatment_for_hypertension, inclusion: [true, false]

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end
