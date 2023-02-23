class Api::V4::Models::Questionnaires::MonthlyScreeningReport
  class << self
    def layout
      {
        type: "group",
        id: "2e8ce537-616c-4c4c-a651-ad065d05f220",
        view_type: "view_group",
        item: [
          {
            type: "display",
            id: "1a1d5af5-af62-4097-8dfb-e7ca297f841a",
            text: "Monthly OPD visits for adults >30 years old",
            view_type: "sub_header"
          },
          {
            id: "964f8d0f-ecaf-4b9e-87e8-62614ff5c7db",
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                id: "3bda5cb0-de8e-463e-9d7c-54a7215e4077",
                link_id: "monthly_screening_reports.outpatient_department_visits",
                text: "Outpatient department visits",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1_000_000
                }
              }
            ]
          },
          {
            type: "display",
            id: "9a1a3cb4-33c1-4acd-a48a-e1fb31debd36",
            view_type: "separator"
          },
          {
            type: "display",
            id: "c2957249-a4d4-43ee-aade-0fb86a04c4ae",
            text: "HTN & DM SCREENING",
            view_type: "header"
          },
          {
            type: "display",
            id: "4e227bc7-1d01-48e2-8186-e5de2109e509",
            text: "Total BP Checks done",
            view_type: "sub_header"
          },
          {
            type: "group",
            id: "b39903c9-04e2-4fd8-9218-6ff5e5cf6466",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                id: "41c2c2fa-2bb2-4b0c-9a89-7d5c11bd4a9b",
                link_id: "monthly_screening_reports.blood_pressure_checks_male",
                text: "Male",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1_000_000
                }
              },
              {
                type: "integer",
                id: "1e999e55-5839-4f6b-9f5e-118b6c5f5728",
                link_id: "monthly_screening_reports.blood_pressure_checks_female",
                text: "Female",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1_000_000
                }
              }
            ]
          },
          {
            type: "display",
            id: "234700ac-645b-47e8-8d17-457ab3c0f53f",
            view_type: "separator"
          },
          {
            type: "display",
            id: "c0777808-7098-4a93-a40c-9860c716d9d3",
            view_type: "line_separator"
          }
        ]
      }
    end
  end
end
