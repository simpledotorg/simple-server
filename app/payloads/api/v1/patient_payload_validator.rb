class Api::V1::PatientPayloadValidator < Api::V1::PayloadValidator

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
    :address,
    :phone_numbers
  )

  validate :validate_schema
  validate :presence_of_age

  def presence_of_age
    unless date_of_birth.present? || (age.present? && age_updated_at.present?)
      errors.add(:age, 'Either date_of_birth or age and age_updated_at should be present')
    end
  end

  def schema
    Api::V1::Schema::Models.nested_patient
  end
end