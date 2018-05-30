class Api::V1::PatientPayload
  include ActiveModel::Model

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

  def initialize(attributes = {})
    @attributes = attributes
    super(attributes)
  end

  def presence_of_age
    unless date_of_birth.present? || (age.present? && age_updated_at.present?)
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

  def model_attributes
    address_attributes       = rename_attributes(address) if address.present?
    phone_numbers_attributes = phone_numbers.map { |phone_number| rename_attributes(phone_number) } if phone_numbers.present?
    patient_attributes       = rename_attributes(@attributes)
    patient_attributes.merge(
      address:       address_attributes,
      phone_numbers: phone_numbers_attributes
    ).with_indifferent_access
  end

  def rename_attributes(attributes)
    key_mapping = {
      created_at: :device_created_at,
      updated_at: :device_updated_at
    }.with_indifferent_access

    attributes.transform_keys { |key| key_mapping[key] || key }
  end
end