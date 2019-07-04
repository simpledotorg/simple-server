class Api::V2::PayloadValidator < Api::Current::PayloadValidator
  def schema_with_definitions
    schema.merge(definitions: Api::V2::Schema.all_definitions)
  end
end
