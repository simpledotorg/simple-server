class Api::Current::NewPayloadValidator
  attr_reader :params, :errors

  def initialize(params = {})
    @params = params
    @errors = nil
  end

  def validate_schema
    @errors ||= JSON::Validator.fully_validate(schema_with_definitions, params.to_json)
  end

  def valid?
    @errors.blank? && validate_schema.blank?
  end

  def invalid?
    !valid?
  end

  def schema_with_definitions
    schema.merge(definitions: Api::Current::Schema.all_definitions)
  end
end
