class Api::Current::PayloadValidator
  include ActiveModel::Model

  def initialize(attributes = {})
    @attributes = attributes.to_hash.with_indifferent_access
    super(attributes)
  end

  def schema_with_definitions
    schema.merge(definitions: Api::Current::Schema.all_definitions)
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