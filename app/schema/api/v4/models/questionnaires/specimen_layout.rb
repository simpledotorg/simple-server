class Api::V4::Models::Questionnaires::SpecimenLayout
  class << self
    def version_1
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
                link_id: "monthly_screening_report.outpatient_department_visits",
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
                link_id: "monthly_screening_report.blood_pressure_checks_male",
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
                link_id: "monthly_screening_report.blood_pressure_checks_female",
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
            id: "c0777808-7098-4a93-a40c-9860c716d9d3",
            view_type: "line_separator"
          }
        ]
      }
    end

    def version_2
      {
        id: "2e8ce537-616c-4c4c-a651-ad065d05f220",
        type: "group",
        view_type: "view_group",
        item: [
          {
            id: "7c660864-b50a-4b3c-b019-c37a3fba3b8e",
            type: "display",
            view_type: "paragraph",
            text: "Enter the supplies left in stock at the end of every month"
          },
          {
            id: "5f98dcc1-504b-473a-bff8-2f1576a85bca",
            type: "group",
            view_type: "unordered_list_view_group",
            item: [
              {
                id: "ac2d9428-cd51-4dc0-9553-a2e7e4bc6edc",
                type: "display",
                view_type: "unordered_list_item",
                icon: "check",
                icon_color: "#00B849",
                text: "Leave blank if you don't know an amount"
              },
              {
                id: "a2f709fd-b4e7-4f3c-aa0f-2369c179d351",
                type: "display",
                view_type: "unordered_list_item",
                icon: "check",
                icon_color: "#00B849",
                text: "Enter \"0\" if stock is out"
              }
            ]
          },
          {
            id: "c2957249-a4d4-43ee-aade-0fb86a04c4ae",
            type: "display",
            text: "EQUIPMENT",
            view_type: "header"
          },
          {
            id: "4e227bc7-1d01-48e2-8186-e5de2109e509",
            type: "display",
            text: "TOTAL available BP devices",
            view_type: "sub_header"
          },
          {
            id: "b39903c9-04e2-4fd8-9218-6ff5e5cf6466",
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                id: "41c2c2fa-2bb2-4b0c-9a89-7d5c11bd4a9b",
                type: "integer",
                link_id: "monthly_supplies_report.total_available_bp_devices",
                text: "Stock on hand",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1_000_000
                }
              }
            ]
          },
          {
            id: "9a1a3cb4-33c1-4acd-a48a-e1fb31debd36",
            type: "display",
            view_type: "separator"
          },
          {
            id: "b0003786-7310-44f5-9509-830d15f121f9",
            type: "display",
            text: "Enough drugs for next month: Losartan",
            view_type: "sub_header"
          },
          {
            id: "74ff3a76-82e1-4770-8d22-bcdc8c2bc70f",
            type: "group",
            view_type: "radio_view_group",
            link_id: "monthly_supplies_report.losartan_enough_for_next_month",
            item: [
              {
                id: "df0eb090-2c6a-4e29-bb32-bcae6c6d7209",
                type: "radio",
                view_type: "radio_button",
                text: "Yes"
              },
              {
                id: "48b3a1d5-7769-4f6b-b417-590c143a2690",
                type: "radio",
                view_type: "radio_button",
                text: "No"
              }
            ]
          },
          {
            id: "c0777808-7098-4a93-a40c-9860c716d9d3",
            type: "display",
            view_type: "line_separator"
          },
          {
            id: "e751a383-c52e-40ad-aea1-7db138c9b734",
            type: "display",
            text: "Comments",
            view_type: "sub_header"
          },
          {
            id: "d7283442-8929-4c18-b6c1-f7bfe83c0927",
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                id: "5c3d4419-8591-43b5-93fb-12349caae93d",
                type: "string",
                link_id: "monthly_supplies_report.comments",
                text: "",
                view_type: "input_field",
                validations: {
                  max_char: 1000
                }
              }
            ]
          }
        ]
      }
    end
  end
end
