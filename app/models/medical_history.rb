class MedicalHistory < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true

  validates :patient, uniqueness: true
  validates :has_prior_heart_attack, inclusion: [true, false]
  validates :has_prior_stroke, inclusion: [true, false]
  validates :has_chronic_kidney_disease, inclusion: [true, false]
  validates :is_on_treatment_for_hypertension, inclusion: [true, false]
end
