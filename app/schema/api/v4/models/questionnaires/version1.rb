class Api::V4::Models::Questionnaires::Version1
  class << self
    def definitions
      {
        questionnaire_layout_dsl_1: layout,
        questionnaire_group_dsl_1: group,
        questionnaire_display_dsl_1: display,
        questionnaire_line_break_dsl_1: line_break,
        questionnaire_integer_input_dsl_1: integer_input
      }
    end

    def layout
      {"$ref" => "#/definitions/questionnaire_group_dsl_1"}
    end

    def group
      {
        type: :object,
        example: Api::V4::Models::Questionnaires::MonthlyScreeningReport.layout,
        properties: {
          type: {type: :string, enum: %w[group]},
          link_id: {type: :string},
          view_type: {type: :string, enum: %w[view_group]},
          display_properties: {
            type: :object,
            properties: {
              orientation: {type: :string, enum: %w[horizontal vertical]}
            },
            required: %w[orientation]
          },
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_group_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_display_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_line_break_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_integer_input_dsl_1"}
              ]
            }
          }
        },
        required: %w[type link_id view_type display_properties item]
      }
    end

    def line_break
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[display]},
          link_id: {type: :string},
          view_type: {type: :string, enum: %w[separator line_separator]}
        },
        required: %w[type link_id view_type]
      }
    end

    def display
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[display]},
          link_id: {type: :string},
          text: {type: :string},
          view_type: {type: :string, enum: %w[header sub_header]}
        },
        required: %w[type link_id text view_type]
      }
    end

    def integer_input
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[integer]},
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
        required: %w[type link_id text view_type validations]
      }
    end
  end
end
