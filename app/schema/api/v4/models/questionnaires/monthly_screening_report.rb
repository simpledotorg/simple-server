class Api::V4::Models::Questionnaires::MonthlyScreeningReport
  class << self
    def layout
      [
        {
          text: "HTN & DM SCREENING",
          type: "display",
          display_properties: {
            view: "header"
          }
        },
        {
          text: "Total BP Checks done",
          type: "display",
          display_properties: {
            view: "sub_header"
          }
        },
        {
          type: "group",
          display_properties: {
            view: "input_group",
            orientation: "horizontal"
          },
          items: [
            {
              link_id: "blood_pressure_checks_male",
              text: "Male",
              type: "integer",
              display_properties: {
                view: "input_field"
              },
              validations: {
                min: 0,
                max: 1000000
              }
            },
            {
              link_id: "blood_pressure_checks_female",
              text: "Female",
              type: "integer",
              display_properties: {
                view: "input_field"
              },
              validations: {
                min: 0,
                max: 1000000
              }
            }
          ]
        },
        {
          type: "display",
          display_properties: {
            view: "separator"
          }
        },
        {
          type: "display",
          display_properties: {
            view: "line_separator"
          }
        }
      ]
    end
  end
end
