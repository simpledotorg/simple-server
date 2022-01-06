# frozen_string_literal: true

class Api::V3::PayloadValidator
  include ActiveModel::Model

  def initialize(attributes = {})
    @attributes = attributes.to_hash.with_indifferent_access
    super(attributes)
  end

  def schema_with_definitions
    schema.merge(definitions: Api::V3::Schema.all_definitions)
  end

  def errors_hash
    errors.to_hash.merge(id: id)
  end

  def validate_schema
    JSON::Validator.fully_validate(schema_with_definitions, to_json).each do |error_string|
      errors.add(:schema, error_string)
    end
  end

  def model_name
    self.class.name.demodulize.gsub(/PayloadValidator/, "")
  end

  def check_invalid?
    if invalid?
      track_invalid
      true
    else
      false
    end
  end

  def track_invalid
    Statsd.instance.increment("merge.#{model_name}.schema_invalid")
  end
end
