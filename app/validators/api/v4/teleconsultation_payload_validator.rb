# frozen_string_literal: true

class Api::V4::TeleconsultationPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :patient_id,
    :medical_officer_id,
    :record,
    :request,
    :updated_at,
    :deleted_at,
    :created_at
  )
  attr_writer :request_user_id

  validate :validate_schema
  validate :authorized_teleconsult_record, if: -> { record.present? }

  def authorized_teleconsult_record
    unless request_user&.can_teleconsult?
      errors.add(
        :user_not_authorized_to_record_this_teleconsult,
        "User is not authorized to record this teleconsult"
      )
    end
  end

  def schema
    Api::V4::Models.teleconsultation
  end

  def request_user
    User.find_by(id: @request_user_id)
  end
end
