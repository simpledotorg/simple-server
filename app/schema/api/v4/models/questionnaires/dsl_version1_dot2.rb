class Api::V4::Models::Questionnaires::DSLVersion1Dot2
  class << self
    def definitions
      {
        questionnaire_view_group_dsl_1_2: view_group,
        questionnaire_input_view_group_dsl_1_2: input_view_group,
        questionnaire_date_input_dsl_1_2: date_input
      }
    end

    def view_group
      {
        type: :object,
        example: Api::V4::Models::Questionnaires::SpecimenLayout::DSLVERSION1DOT2,
        properties: {
          type: {type: :string, enum: %w[group]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[view_group]},
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_display_dsl_1_1"},
                {"$ref" => "#/definitions/questionnaire_unordered_list_view_group_dsl_1_1"},
                {"$ref" => "#/definitions/questionnaire_line_break_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_input_view_group_dsl_1_2"},
                {"$ref" => "#/definitions/questionnaire_radio_view_group_dsl_1_1"}
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
                {"$ref" => "#/definitions/questionnaire_integer_input_dsl_1"},
                {"$ref" => "#/definitions/questionnaire_string_input_dsl_1_1"},
                {"$ref" => "#/definitions/questionnaire_date_input_dsl_1_2"}
              ]
            }
          }
        },
        required: %w[type id view_type item]
      }
    end

    def date_input
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[date]},
          id: {"$ref" => "#/definitions/uuid"},
          link_id: {type: :string},
          text: {type: :string},
          view_type: {type: :string, enum: %w[month_year_picker]},
          view_format: {
            type: :string,
            description: "A pattern parseable by Kotlin's DateTimeFormatter for rendering dates on Android apps. For ex: \"MMM yyyy\""
          },
          validations: {
            type: :object,
            properties: {
              allowed_days_in_past: {
                type: :integer,
                description: "Maximum permissible days in the past from current date."
              },
              allowed_days_in_future: {
                type: :integer,
                description: "Maximum permissible days in the future from current date."
              }
            },
            required: %w[allowed_days_in_past allowed_days_in_future]
          }
        },
        required: %w[type id link_id text view_type view_format validations]
      }
    end
  end
end
