class Api::V1::BloodPressurePayload
  include ActiveModel::Model

  attr_accessor(
    :id,
    :systolic,
    :diastolic,
    :patient_id,
    :created_at,
    :updated_at
  )

  validate :validate_schema

  def initialize(attributes = {})
    @attributes = attributes
    super(attributes)
  end

  def schema
    Api::V1::Spec.blood_pressure_spec
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
    rename_attributes(@attributes).with_indifferent_access
  end

  def rename_attributes(attributes)
    key_mapping = {
      created_at: :device_created_at,
      updated_at: :device_updated_at
    }.with_indifferent_access

    attributes.transform_keys { |key| key_mapping[key] || key }
  end
end