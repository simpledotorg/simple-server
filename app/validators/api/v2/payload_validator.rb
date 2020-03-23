class Api::V2::PayloadValidator < Api::V3::PayloadValidator
  def schema_with_definitions
    schema.merge(definitions: Api::V2::Schema.all_definitions)
  end
end
