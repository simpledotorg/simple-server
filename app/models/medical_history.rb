class MedicalHistory < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true
  belongs_to :user, optional: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  MEDICAL_HISTORY_QUESTIONS = [
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :receiving_treatment_for_diabetes,
    :diabetes,
    :diagnosed_with_hypertension,
    :smoking,
    :smokeless_tobacco
  ].freeze

  MEDICAL_HISTORY_ANSWERS = {
    yes: "yes",
    no: "no",
    unknown: "unknown"
  }.freeze

  enum prior_heart_attack: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum prior_stroke: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum chronic_kidney_disease: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum receiving_treatment_for_hypertension: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum receiving_treatment_for_diabetes: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum smoking: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum smokeless_tobacco: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum diabetes: MEDICAL_HISTORY_ANSWERS.merge(suspected: "suspected"), _prefix: true
  enum hypertension: MEDICAL_HISTORY_ANSWERS.merge(suspected: "suspected"), _prefix: true
  enum diagnosed_with_hypertension: MEDICAL_HISTORY_ANSWERS.merge(suspected: "suspected"), _prefix: true

  scope :for_sync, -> { with_discarded }

  validate :validate_immutable_diagnosis_dates, on: :update

  after_save :update_patient_diagnosed_confirmed_at

  def indicates_hypertension_risk?
    prior_heart_attack_yes? || prior_stroke_yes?
  end

  def validate_immutable_diagnosis_dates
    if will_save_change_to_htn_diagnosed_at? && htn_diagnosed_at_was.present?
      errors.add(:htn_diagnosed_at, "Hypertension diagnosis date has already been recorded and cannot be changed.")
    end

    if will_save_change_to_dm_diagnosed_at? && dm_diagnosed_at_was.present?
      errors.add(:dm_diagnosed_at, "Diabetes diagnosis date has already been recorded and cannot be changed.")
    end
  end

  def update_patient_diagnosed_confirmed_at
    return unless patient
    return if patient.diagnosed_confirmed_at.present?

    if htn_diagnosed_at.present? || dm_diagnosed_at.present?
      earliest = [htn_diagnosed_at, dm_diagnosed_at].compact.min
      patient.update_columns(diagnosed_confirmed_at: earliest)
      return
    end

    if htn_diagnosed_at.nil? && dm_diagnosed_at.nil?
      return if hypertension_suspected? || diabetes_suspected?

      if (hypertension_yes? || hypertension_no?) || (diabetes_yes? || diabetes_no?)
        if patient.diagnosed_confirmed_at.nil? && patient.recorded_at.present?
          patient.update_columns(diagnosed_confirmed_at: patient.recorded_at)
        end
      end
      nil
    end
  end
end
