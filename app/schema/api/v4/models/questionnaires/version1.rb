class Api::V4::Models::Questionnaires::Version1
  class << self
    def definitions
      {
        questionnaire_layout_dsl_version_1: questionnaire_layout,
        questionnaire_integer_input: questionnaire_integer_input,
        questionnaire_group: questionnaire_group
      }
    end

    def questionnaire_layout
      {
        type: :object,
        properties: {
          item: {type: :array, items: {"$ref" => "#/definitions/questionnaire_group"}}
        }
      }
    end

    def questionnaire_group
      {
        type: :object,
        properties: {
          link_id: {type: :string},
          text: {type: :string},
          type: {type: :string, enum: %w[group]},
          display: {
            type: :object,
            properties: {
              orientation: {type: :string, enum: %w[vertical horizontal]},
              view_type: {type: :string, enum: %w[header sub_header]}
            },
            required: %w[orientation view_type]
          },
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_group"},
                {"$ref" => "#/definitions/questionnaire_integer_input"}
              ]
            }
          }
        },
        required: %w[link_id text type display item]
      }
    end

    def questionnaire_integer_input
      {
        type: :object,
        properties: {
          link_id: {type: :string},
          text: {type: :string},
          type: {type: :string, enum: %w[integer]},
          display:
            {
              type: :object,
              properties: {
                view_type: {type: :string, enum: %w[input_field]}
              },
              required: %w[view_type]
            },
          validations: {
            type: :object,
            properties: {
              min: {type: :integer},
              max: {type: :integer}
            },
            required: %w[min max]
          }
        },
        required: %w[link_id text type display validations]
      }
    end

  end
end
