class Api::V4::Models::Questionnaires::Version1
  class << self
    def definitions
      {
        questionnaire_view_group_dsl_1: view_group,
        questionnaire_input_view_group_dsl_1: input_view_group,
        questionnaire_display_dsl_1: display,
        questionnaire_line_break_dsl_1: line_break,
        questionnaire_integer_input_dsl_1: integer_input
      }
    end

    def view_group
      {
        type: :object,
        example: Api::V4::Models::Questionnaires::MonthlyScreeningReport.layout,
        properties: {
          type: {type: :string, enum: %w[group]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[view_group]},
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_input_view_group_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_display_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_line_break_dsl_1"}
              ]
            }
          }
        },
        required: %w[type id view_type item]
      }
    end

    def input_view_group
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[group]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[input_view_group]},
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_integer_input_dsl_1"}
              ]
            }
          }
        },
        required: %w[type id view_type item]
      }
    end

    def line_break
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[display]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[separator line_separator]}
        },
        required: %w[type id view_type]
      }
    end

    def display
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[display]},
          id: {"$ref" => "#/definitions/uuid"},
          text: {type: :string},
          view_type: {type: :string, enum: %w[header sub_header]}
        },
        required: %w[type id text view_type]
      }
    end

    def integer_input
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[integer]},
          id: {"$ref" => "#/definitions/uuid"},
          link_id: {type: :string},
          text: {type: :string},
          view_type: {type: :string, enum: %w[input_field]},
          validations: {
            type: :object,
            properties: {
              min: {type: :integer},
              max: {type: :integer}
            },
            required: %w[min max]
          }
        },
        required: %w[type id link_id text view_type validations]
      }
    end
  end
end
