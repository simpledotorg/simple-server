# frozen_string_literal: true

class Api::V3::PatientPayloadValidator < Api::V3::PayloadValidator
  attr_accessor(
    :id,
    :full_name,
    :age,
    :gender,
    :date_of_birth,
    :status,
    :age_updated_at,
    :created_at,
    :updated_at,
    :recorded_at,
    :deleted_at,
    :address,
    :phone_numbers,
    :registration_facility_id,
    :assigned_facility_id,
    :business_identifiers,
    :contacted_by_counsellor,
    :could_not_contact_reason,
    :call_result,
    :reminder_consent,
    :deleted_reason,
    :skip_facility_authorization
  )

  attr_writer :request_user_id

  validate :validate_schema, unless: -> { FeatureToggle.enabled?("SKIP_API_VALIDATION") }
  validate :presence_of_age
  validate :past_date_of_birth
  validate :authorized_assigned_facility, unless: :skip_facility_authorization
  validate :authorized_registration_facility, unless: :skip_facility_authorization

  def presence_of_age
    unless date_of_birth.present? || (age.present? && age_updated_at.present?)
      errors.add(:age, "Either date_of_birth or age and age_updated_at should be present")
    end
  end

  def past_date_of_birth
    if date_of_birth.present? && date_of_birth.to_s.to_time > Date.current
      errors.add(:date_of_birth, "can't be in the future")
    end
  end

  def authorized_assigned_facility
    unless authorized_facility?(assigned_facility_id)
      errors.add(
        :assigned_facility_does_not_belong_to_user,
        "Assigned facility must belong to the Facility Group of the User"
      )
    end
  end

  def authorized_registration_facility
    unless authorized_facility?(registration_facility_id)
      errors.add(
        :registration_facility_does_not_belong_to_user,
        "Registration facility must belong to the Facility Group of the User"
      )
    end
  end

  def schema
    Api::V3::Models.nested_patient
  end

  private

  def authorized_facility?(facility_id)
    return true if facility_id.blank?

    request_user.present? && request_user.authorized_facility?(facility_id)
  end

  def request_user
    User.find_by(id: @request_user_id)
  end
end
