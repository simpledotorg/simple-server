class Api::V1::PatientPayload
  include ActiveModel::Model

  # todo
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

  def build_model
    patient_address       = Address.new(rename_attributes(address)) if address.present?
    patient_phone_numbers = phone_numbers.map { |phone_number| PatientPhoneNumber.new(rename_attributes(phone_number))} if phone_numbers.present?
    patient               = Patient.new(@attributes.except('address', 'phone_numbers'))
    patient.address       = patient_address
    patient.phone_numbers = patient_phone_numbers
    patient
  end

  private

  def rename_attributes(attributes)
    rename_keys = {
      created_at: :device_created_at,
      updated_at: :device_updated_at
    }.with_indifferent_access

    Hash[attributes.map { |key, value| rename_keys[key].present? ? [rename_keys[key], value] : [key, value] }]
  end
end