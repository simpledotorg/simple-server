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

  before_validation :silently_enforce_medical_history_rules

  after_save :update_patient_diagnosed_confirmed_at

  def indicates_hypertension_risk?
    prior_heart_attack_yes? || prior_stroke_yes?
  end

  private

  def silently_enforce_medical_history_rules
    enforce_one_way_enums_silently
    enforce_date_rules_silently
  end

  def enforce_one_way_enums_silently
    %i[hypertension diabetes diagnosed_with_hypertension].each do |attr|
      prev = send("#{attr}_was")
      curr = send(attr)

      next if prev.blank? || prev.to_s == curr.to_s

      prev_s = prev.to_s
      curr_s = curr.to_s

      if prev_s == "suspected"
        next if %w[yes no suspected].include?(curr_s)
      end

      if prev_s == "no" && curr_s == "yes"
        date_field =
          case attr
          when :hypertension then :htn_diagnosed_at
          when :diabetes then :dm_diagnosed_at
          end

        if date_field && send(date_field).present?
          next
        end
      end

      write_attribute(attr, prev_s)
      Rails.logger.info("[MedicalHistory] Silently reverted #{attr} from #{curr_s} -> #{prev_s} for medical_history_id=#{id || "new"}")
    end
  end

  def enforce_date_rules_silently
    self.htn_diagnosed_at = nil unless %w[yes no].include?(hypertension&.to_s)
    self.dm_diagnosed_at = nil unless %w[yes no].include?(diabetes&.to_s)

    if htn_diagnosed_at_was.present? && !timestamps_equal?(htn_diagnosed_at, htn_diagnosed_at_was)
      write_attribute(:htn_diagnosed_at, htn_diagnosed_at_was)
      Rails.logger.info("[MedicalHistory] Silently preserved existing htn_diagnosed_at for id=#{id || "new"}")
    end

    if dm_diagnosed_at_was.present? && !timestamps_equal?(dm_diagnosed_at, dm_diagnosed_at_was)
      write_attribute(:dm_diagnosed_at, dm_diagnosed_at_was)
      Rails.logger.info("[MedicalHistory] Silently preserved existing dm_diagnosed_at for id=#{id || "new"}")
    end
  end

  def update_patient_diagnosed_confirmed_at
    return unless patient
    return if patient.diagnosed_confirmed_at.present?

    valid_htn_date = htn_diagnosed_at.present? && %w[yes no].include?(hypertension&.to_s)
    valid_dm_date = dm_diagnosed_at.present? && %w[yes no].include?(diabetes&.to_s)

    if valid_htn_date || valid_dm_date
      earliest = [
        (htn_diagnosed_at if valid_htn_date),
        (dm_diagnosed_at if valid_dm_date)
      ].compact.min
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

  def timestamps_equal?(a, b)
    a&.change(usec: 0) == b&.change(usec: 0)
  end
end
