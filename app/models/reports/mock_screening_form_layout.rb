# frozen_string_literal: true

module Reports::MockScreeningFormLayout
  LAYOUT = JSON.parse(<<~JSON.freeze).freeze
    {
      "id": "b6ed5ff9-1d52-42aa-8f95-73ba27948b72",
      "item": [
        {
          "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
          "text": "monthly_screening_report.annual_target",
          "type": "display",
          "view_type": "header"
        },
        {
          "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
          "item": [
            {
              "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
              "text": "monthly_screening_report.annual_target",
              "type": "integer",
              "link_id": "monthly_screening_report.annual_target",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "d4e5f6a7-b8c9-0123-def0-234567890123",
          "type": "display",
          "view_type": "separator"
        },
        {
          "id": "48a3f791-21bd-4679-a9b2-44cc78adfd7f",
          "text": "monthly_screening_report.htn_and_dm_screening",
          "type": "display",
          "view_type": "header"
        },
        {
          "id": "5b43fc37-cd16-4efe-9f22-741d009a7bd0",
          "text": "monthly_screening_report.total_bp",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "2ec104fa-7757-4eb8-a8a8-daa0416b5332",
          "item": [
            {
              "id": "492eb65b-7dff-46bf-bbf9-3954a5593990",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_bp_screening",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "5aaf1e41-121f-4809-9e69-8a0b67416731",
          "text": "monthly_screening_report.total_bs",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "07b53305-8bff-40f8-adc5-e1d2f7ccd942",
          "item": [
            {
              "id": "266353e1-718f-4e8b-89c6-facf392238b0",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_bs_screening",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "b1219f28-71af-4561-b040-b8cdc0fdc92e",
          "type": "display",
          "view_type": "separator"
        },
        {
          "id": "5b1ef20d-c628-49ec-8dd5-f9d2d7e2b730",
          "text": "monthly_screening_report.new_raised_cases",
          "type": "display",
          "view_type": "header"
        },
        {
          "id": "65110ed5-33ed-4df4-8d93-01338d36d980",
          "text": "monthly_screening_report.total_bp_raised",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "9adb1af2-5933-441e-b88f-f98206e4338a",
          "item": [
            {
              "id": "0188c149-d382-43f4-8b37-7eb097ec8fc2",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_bp_raised",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "c831d98f-e993-4e21-bfc0-f6122b9da639",
          "text": "monthly_screening_report.total_bs_raised",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "be5af57e-7c25-4ce9-a151-717e954685c9",
          "item": [
            {
              "id": "cfbff08b-2357-4d86-ab3a-9c8c22312c74",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_bs_raised",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "9689b675-5efb-4e3e-a2d4-35f14e914dc6",
          "text": "monthly_screening_report.total_bp_raised_ncd_linked",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "6761caf8-b304-447e-910d-7b9ffd789eb3",
          "item": [
            {
              "id": "9acbb51b-ad31-43cd-bdd0-172280ad4035",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_bp_raised_ncd_linked",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "0653a8e2-617f-4db5-8e2f-fa219b4b8ede",
          "text": "monthly_screening_report.total_bs_raised_ncd_linked",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "02e3d040-332e-4bdb-bcdb-2d6326fdf8a3",
          "item": [
            {
              "id": "061cca47-dbe9-4f06-8b0c-c771f37688a8",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_bs_raised_ncd_linked",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "27bd706b-89d2-4957-9c6a-35fab8964873",
          "type": "display",
          "view_type": "separator"
        },
        {
          "id": "3fd4a87d-2582-4e34-aead-eb02dbc75743",
          "text": "monthly_screening_report.diagnosed_cases",
          "type": "display",
          "view_type": "header"
        },
        {
          "id": "ab08fced-2717-4e02-ab59-997920623ed0",
          "text": "monthly_screening_report.total_htn_diagnosed",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "85123fe9-1308-4b70-b6a1-3fae82c0d5cb",
          "item": [
            {
              "id": "ee64c028-f3a0-4d09-ae0e-c364e2546d02",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_htn_diagnosed",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "a3dd1d33-940d-4a7a-9757-364fdf80dd36",
          "text": "monthly_screening_report.total_dm_diagnosed",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "a8eadc73-8c30-47c7-aa06-2c023424ab2c",
          "item": [
            {
              "id": "d0202069-4a4f-417a-bc88-c44e26d2e063",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_dm_diagnosed",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "d3ddf4bb-4394-4afc-bf3d-527edfd7d0b8",
          "type": "display",
          "view_type": "line_separator"
        },
        {
          "id": "84a8472f-96bf-429a-ad47-fa0b60b4f73c",
          "text": "monthly_screening_report.cervical_cancer_uc",
          "type": "display",
          "view_type": "header"
        },
        {
          "id": "54bf8468-a159-4276-948d-099ddd98aeb7",
          "text": "monthly_screening_report.total_women_screened_cervical",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "7be879bb-fe89-4807-bbb8-5cf4ea78efca",
          "item": [
            {
              "id": "aeb425c5-956c-446e-aa29-fa68ccfb60ce",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_women_screened_cervical",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "f644d69a-2162-44f1-a44d-dd2c97d43c64",
          "text": "monthly_screening_report.total_women_screened_via_screening_result",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "1b2e5cbf-60d0-4bdb-9195-35d783ff8d55",
          "item": [
            {
              "id": "6d8d2067-5654-4379-aa05-bc147a3783b7",
              "text": "questionnaire_layout.negative",
              "type": "integer",
              "link_id": "monthly_screening_report.total_women_screened_via_screening_result.negative",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "4b19c390-62ae-4009-9896-5d244ac8ea4e",
          "item": [
            {
              "id": "5d0bc40f-aa5b-4977-89a4-971312bb16f6",
              "text": "questionnaire_layout.positive",
              "type": "integer",
              "link_id": "monthly_screening_report.total_women_screened_via_screening_result.positive",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "f6d3bc6a-badf-4903-9bb2-8dba69d6a809",
          "item": [
            {
              "id": "491cf5e5-d384-4ad0-9791-71674c13c92b",
              "text": "questionnaire_layout.not_eligible",
              "type": "integer",
              "link_id": "monthly_screening_report.total_women_screened_via_screening_result.not_eligible",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "ba50664f-b05b-44eb-a016-c7cb39dd374a",
          "item": [
            {
              "id": "9dc2dd92-dadd-456d-a1ce-04336b3a2b31",
              "text": "questionnaire_layout.suspicious_cancer",
              "type": "integer",
              "link_id": "monthly_screening_report.total_women_screened_via_screening_result.suspicious_cancer",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        },
        {
          "id": "b51baeae-61ab-4d34-a696-b54d6273c6ae",
          "text": "monthly_screening_report.total_women_followup_cervical",
          "type": "display",
          "view_type": "sub_header"
        },
        {
          "id": "c2813f7f-cc95-413f-a52b-871497df9370",
          "item": [
            {
              "id": "8f2a84f0-9bef-42aa-b2ab-9b7421a9565b",
              "text": "questionnaire_layout.total",
              "type": "integer",
              "link_id": "monthly_screening_report.total_women_followup_cervical",
              "view_type": "input_field",
              "validations": {
                "max": 100000,
                "min": 0
              }
            }
          ],
          "type": "group",
          "view_type": "input_view_group"
        }
      ],
      "type": "group",
      "view_type": "view_group"
    }
  JSON
end
