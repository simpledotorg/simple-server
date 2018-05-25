class Api::V1::PatientPayload
  include ActiveModel::Model

  # - swagger validation
  # - build errors

  # - custom validation
  # - build errors
  # - coerce params to ruby/rails data types
  # - build errors
  # - rename keys
  # - structure payload object?

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

  validate :presence_of_age
  validate :validate_schema

  def presence_of_age
    unless date_of_birth.present? || (age.present? && age_updated_at.present? && age_updated_at.to_time.present?)
      errors.add(:age, 'Either date_of_birth or age and age_updated_at should be present')
    end
  end

  def schema
    Api::V1::Spec.nested_patient
  end

  def schema_with_definitions
    schema.merge(definitions: Api::V1::Spec.all_definitions)
  end

  def errors_hash
    errors.to_hash.merge(id: id)
  end

  def validate_schema
    JSON::Validator.fully_validate(schema_with_definitions, to_json).each do |error_string|
      errors.add(:schema, error_string)
    end
  end
end