require_dependency "seed/config"

module Seed
  class QuestionnaireSeeder
    def self.call
      FactoryBot.create(:questionnaire,
        questionnaire_type: "monthly_screening_reports",
        dsl_version: "1",
        is_active: true,
        description: "A specimen screening report created during seeding.",
        layout: screening_reports_seed_layout)

      FactoryBot.create(:questionnaire,
        questionnaire_type: "monthly_supplies_reports",
        dsl_version: "1.1",
        is_active: true,
        description: "specimen report, supplies report, dsl version 1.1",
        layout: supplies_reports_seed_layout)

      FactoryBot.create(:questionnaire,
        questionnaire_type: "drug_stock_reports",
        dsl_version: "1.2",
        is_active: true,
        description: "specimen report, drug stock report, dsl version 1.2",
        layout: drug_stock_reports_seed_layout)

      (1..3).map do |n|
        QuestionnaireResponses::MonthlyScreeningReports.new(n.month.ago).pre_fill
        QuestionnaireResponses::MonthlySuppliesReports.new(n.month.ago).seed
        QuestionnaireResponses::DrugStockReports.new(n.month.ago).seed
      end
    end

    def self.screening_reports_seed_layout
      {
        type: "group",
        view_type: "view_group",
        item: [
          {
            type: "display",
            text: "monthly_screening_report.monthly_opd_visits_gt_30",
            view_type: "sub_header"
          },
          {
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                link_id: "monthly_screening_report.outpatient_department_visits",
                text: "monthly_screening_report.outpatient_department_visits",
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
            view_type: "separator"
          },
          {
            type: "display",
            text: "monthly_screening_report.htn_and_dm_screening",
            view_type: "header"
          },
          {
            type: "display",
            text: "monthly_screening_report.total_bp",
            view_type: "sub_header"
          },
          {
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                link_id: "monthly_screening_report.blood_pressure_checks_male",
                text: "questionnaire_layout.male",
                view_type: "input_field",
                validations: {
                  min: 0,
                  max: 1_000_000
                }
              },
              {
                type: "integer",
                link_id: "monthly_screening_report.blood_pressure_checks_female",
                text: "questionnaire_layout.female",
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
            view_type: "line_separator"
          }
        ]
      }
    end

    def self.supplies_reports_seed_layout
      {
        type: "group",
        view_type: "view_group",
        item: [
          {
            type: "display",
            view_type: "paragraph",
            text: "monthly_supplies_report.instruction_1"
          },
          {
            type: "group",
            view_type: "unordered_list_view_group",
            item: [
              {
                type: "display",
                view_type: "unordered_list_item",
                icon: "check",
                icon_color: "#00B849",
                text: "questionnaire_layout.instruction_1"
              },
              {
                type: "display",
                view_type: "unordered_list_item",
                icon: "check",
                icon_color: "#00B849",
                text: "questionnaire_layout.instruction_2"
              }
            ]
          },
          {
            type: "display",
            text: "monthly_supplies_report.equipment",
            view_type: "header"
          },
          {
            type: "display",
            text: "monthly_supplies_report.available_bp_devices",
            view_type: "sub_header"
          },
          {
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                link_id: "monthly_supplies_report.total_available_bp_devices",
                text: "monthly_supplies_report.stock_on_hand",
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
            view_type: "separator"
          },
          {
            type: "display",
            text: "monthly_supplies_report.drug_stock_losartan",
            view_type: "sub_header"
          },
          {
            type: "group",
            view_type: "radio_view_group",
            link_id: "monthly_supplies_report.losartan_enough_for_next_month",
            item: [
              {
                type: "radio",
                view_type: "radio_button",
                text: "questionnaire_layout.yes_lc"
              },
              {
                type: "radio",
                view_type: "radio_button",
                text: "questionnaire_layout.no_lc"
              }
            ]
          },
          {
            type: "display",
            view_type: "line_separator"
          },
          {
            type: "display",
            text: "questionnaire_layout.comments",
            view_type: "sub_header"
          },
          {
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "string",
                link_id: "monthly_supplies_report.comments",
                text: "questionnaire_layout.empty",
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

    def self.drug_stock_reports_seed_layout
      {
        view_type: "view_group",
        type: "group",
        item: [
          {
            "type" => "display",
            "view_type" => "paragraph",
            "text" => "drug_stock_report.instruction_1"
          },
          {
            "type" => "group",
            "view_type" => "unordered_list_view_group",
            "item" => [
              {
                "type" => "display",
                "view_type" => "unordered_list_item",
                "icon" => "check",
                "icon_color" => "#00B849",
                "text" => "questionnaire_layout.instruction_1"
              },
              {
                "type" => "display",
                "view_type" => "unordered_list_item",
                "icon" => "check",
                "icon_color" => "#00B849",
                "text" => "questionnaire_layout.instruction_2"
              }
            ]
          },
          {
            type: "display",
            view_type: "header",
            text: "drug_stock_report.amlodipine_5mg"
          },
          {
            type: "display",
            view_type: "sub_header",
            text: "drug_stock_report.batch_1"
          },
          {
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                view_type: "input_field",
                text: "monthly_supplies_report.stock_on_hand",
                link_id: "drug_stock_report.amlodipine_5mg.batch_1.stock",
                validations: {
                  min: 0,
                  max: 100_000
                }
              },
              {
                type: "date",
                view_type: "month_year_picker",
                text: "drug_stock_report.expiry_date",
                link_id: "drug_stock_report.amlodipine_5mg.batch_1.expiry_date",
                view_format: "MMM YYYY",
                validations: {
                  allowed_days_in_past: 60,
                  allowed_days_in_future: 1825
                }
              }
            ]
          },
          {
            type: "display",
            view_type: "sub_header",
            text: "drug_stock_report.batch_2"
          },
          {
            type: "group",
            view_type: "input_view_group",
            item: [
              {
                type: "integer",
                view_type: "input_field",
                text: "monthly_supplies_report.stock_on_hand",
                link_id: "drug_stock_report.amlodipine_5mg.batch_2.stock",
                validations: {
                  min: 0,
                  max: 100_000
                }
              },
              {
                type: "date",
                view_type: "month_year_picker",
                text: "drug_stock_report.expiry_date",
                link_id: "drug_stock_report.amlodipine_5mg.batch_2.expiry_date",
                view_format: "MMM YYYY",
                validations: {
                  allowed_days_in_past: 60,
                  allowed_days_in_future: 1825
                }
              }
            ]
          }
        ]
      }
    end
  end
end
