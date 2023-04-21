class Api::V4::Models::Questionnaires::Version2
  class << self
    def definitions
      {
        questionnaire_view_group_dsl_2: view_group,
        questionnaire_display_dsl_2: display,
        questionnaire_line_break_dsl_2: Api::V4::Models::Questionnaires::Version1.line_break,
        questionnaire_unordered_list_view_group_dsl_2: unordered_list_view_group,
        questionnaire_unordered_list_item_dsl_2: unordered_list_item,
        questionnaire_radio_view_group_dsl_2: radio_view_group,
        questionnaire_radio_button_dsl_2: radio_button,
        questionnaire_input_view_group_dsl_2: input_view_group,
        questionnaire_integer_input_dsl_2: Api::V4::Models::Questionnaires::Version1.integer_input,
        questionnaire_string_input_dsl_2: string_input
      }
    end

    def view_group
      {
        type: :object,
        example: Api::V4::Models::Questionnaires::SpecimenLayout.version_2,
        properties: {
          type: {type: :string, enum: %w[group]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[view_group]},
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_display_dsl_2"},
                {"$ref" => "#/definitions/questionnaire_unordered_list_view_group_dsl_2"},
                {"$ref" => "#/definitions/questionnaire_line_break_dsl_2"},
                {"$ref" => "#/definitions/questionnaire_input_view_group_dsl_2"},
                {"$ref" => "#/definitions/questionnaire_radio_view_group_dsl_2"}
              ]
            }
          }
        },
        required: %w[type id view_type item]
      }
    end

    def display
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[display]},
          id: {"$ref" => "#/definitions/uuid"},
          text: {type: :string},
          view_type: {type: :string, enum: %w[header sub_header paragraph]}
        },
        required: %w[type id text view_type]
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
                {"$ref" => "#/definitions/questionnaire_integer_input_dsl_2"},
                {"$ref" => "#/definitions/questionnaire_string_input_dsl_2"}
              ]
            }
          }
        },
        required: %w[type id view_type item]
      }
    end

    def string_input
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[string]},
          id: {"$ref" => "#/definitions/uuid"},
          link_id: {type: :string},
          text: {type: :string},
          view_type: {type: :string, enum: %w[input_field]},
          validations: {
            type: :object,
            properties: {
              max_char: {type: :integer}
            },
            required: %w[max_char]
          }
        },
        required: %w[type id link_id text view_type validations]
      }
    end

    def unordered_list_view_group
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[group]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[unordered_list_view_group]},
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_unordered_list_item_dsl_2"}
              ]
            }
          }
        },
        required: %w[type id view_type item]
      }
    end

    def unordered_list_item
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[display]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[unordered_list_item]},
          icon: {type: :string},
          icon_color: {type: :string},
          text: {type: :string}
        },
        required: %w[type id view_type icon icon_color text]
      }
    end

    def radio_view_group
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[group]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[radio_view_group]},
          link_id: {type: :string},
          item: {
            type: :array,
            items: {
              oneOf: [
                {"$ref" => "#/definitions/questionnaire_radio_button_dsl_2"}
              ]
            }
          }
        },
        required: %w[type id view_type link_id item]
      }
    end

    def radio_button
      {
        type: :object,
        properties: {
          type: {type: :string, enum: %w[radio]},
          id: {"$ref" => "#/definitions/uuid"},
          view_type: {type: :string, enum: %w[radio_button]},
          text: {type: :string}
        },
        required: %w[type id view_type text]
      }
    end
  end
end
