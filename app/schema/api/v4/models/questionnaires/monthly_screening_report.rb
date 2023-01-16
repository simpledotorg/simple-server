class Api::V4::Models::Questionnaires::MonthlyScreeningReport
  class << self
    def layout
      {
        type: "group",
        view_type: "view_group",
        display_properties: {
          orientation: "vertical"
        },
        item: [
          {
            text: "Monthly OPD visits for adults >30 years old",
            type: "display",
            view_type: "sub_header"
          },
          {
            link_id: "outpatient_department_visits",
            text: "Outpatient department visits",
            type: "integer",
            view_type: "input_field",
            validations: {
              min: 0,
              max: 1000000
            }
          },
          {
            type: "display",
            view_type: "separator"
          },
          {
            text: "HTN & DM SCREENING",
            type: "display",
            view_type: "header"
          },
          {
            text: "Total BP Checks done",
            type: "display",
            view_type: "sub_header"
          },
          {
            type: "group",
            view_type: "view_group",
            display_properties: {
              orientation: "horizontal"
            },
            item: [
              {
                link_id: "blood_pressure_checks_male",
                text: "Male",
                type: "integer",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1000000
                }
              },
              {
                link_id: "blood_pressure_checks_female",
                text: "Female",
                type: "integer",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1000000
                }
              }
            ]
          },
          {
            type: "display",
            view_type: "separator"
          },
          {
            type: "display",
            view_type: "line_separator"
          }
        ]
      }
    end
  end
end
