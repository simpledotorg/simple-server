# frozen_string_literal: true

class PatientBusinessIdentifier < ApplicationRecord
  include Mergeable

  belongs_to :patient
  has_one :passport_authentication

  enum identifier_type: {
    simple_bp_passport: "simple_bp_passport",
    bangladesh_national_id: "bangladesh_national_id",
    sri_lanka_national_id: "sri_lanka_national_id",
    sri_lanka_personal_health_number: "sri_lanka_personal_health_number",
    ethiopia_medical_record: "ethiopia_medical_record",
    india_national_health_id: "india_national_health_id"
  }

  validate :identifier_present
  validates :identifier_type, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  # We want to allow blank values (but not nil) for Bangladesh because of legacy reasons,
  # and prevent blank _and_ nil for all other identifier types.
  def identifier_present
    if identifier_type == "bangladesh_national_id"
      if identifier.nil?
        errors.add(:identifier, "can't be blank")
      end
    elsif identifier.blank?
      errors.add(:identifier, "can't be blank")
    end
  end

  def shortcode
    if simple_bp_passport?
      identifier.split(/[^\d]/).join[0..6].insert(3, "-")
    else
      identifier
    end
  end
end
