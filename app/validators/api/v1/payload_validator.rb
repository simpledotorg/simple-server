class Api::V1::PayloadValidator < Api::V2::PayloadValidator
  def schema_with_definitions
    schema.merge(definitions: Api::V1::Schema.all_definitions)
  end
end
