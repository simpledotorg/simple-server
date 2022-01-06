# frozen_string_literal: true

class Api::V4::BloodSugarPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :blood_sugar_type,
    :blood_sugar_value,
    :patient_id,
    :facility_id,
    :user_id,
    :created_at,
    :updated_at,
    :deleted_at,
    :recorded_at
  )

  validate :validate_schema
  validate :facility_exists

  def schema
    Api::V4::Models.blood_sugar
  end

  def facility_exists
    unless Facility.exists?(facility_id)
      Rails.logger.info "Blood sugar #{id} synced at nonexistent facility #{facility_id}"
      errors.add(:facility_does_not_exist, "Facility does not exist")
    end
  end
end
