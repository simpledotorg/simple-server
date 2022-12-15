class Api::V4::Models::Questionnaires::MonthlyScreeningReport
  class << self
    def layout
      {"item" => [
        {"link_id" => "monthly_opd_visits",
         "text" => "Monthly OPD visits for adults >30 years old",
         "type" => "group",
         "display" => {
           "view_type" => "sub_header",
           "orientation" => "vertical"
         },
         "item" => [
           {"link_id" => "outpatient_department_visits",
            "text" => "Outpatient department visits",
            "type" => "integer",
            "validations" => {
              "min" => 0,
              "max" => 1000000
            },
            "display" => {"view_type" => "input_field", "orientation" => "vertical"}}
         ]},
        {"link_id" => "htm_and_dm_screening",
         "text" => "HTN & DM SCREENING",
         "type" => "group",
         "display" => {"view_type" => "header_group", "orientation" => "vertical"},
         "item" =>
            [{"link_id" => "total_bp_checks",
              "text" => "Total BP Checks done",
              "type" => "group",
              "display" => {"view_type" => "sub_header", "orientation" => "horizontal"},
              "item" =>
                 [{"link_id" => "blood_pressure_checks_male",
                   "text" => "Male",
                   "type" => "integer",
                   "validations" => {"min" => 0, "max" => 1000000},
                   "display" => {"view_type" => "input_field"}},
                   {"link_id" => "blood_pressure_checks_female",
                    "text" => "Female",
                    "type" => "integer",
                    "validations" => {"min" => 0, "max" => 1000000},
                    "display" => {"view_type" => "input_field"}}]},
              {"link_id" => "total_blood_sugar_checks",
               "text" => "Total blood sugar checks done",
               "display" =>
                  {"view_type" => "sub_header_group", "orientation" => "horizontal"},
               "item" =>
                  [{"link_id" => "blood_sugar_checks_male",
                    "text" => "Male",
                    "type" => "integer",
                    "display" => {"view_type" => "input_field"},
                    "validations" => {"min" => 0, "max" => 1000000}},
                    {"link_id" => "blood_sugar_checks_female",
                     "text" => "Female",
                     "type" => "integer",
                     "display" => {"view_type" => "input_field"},
                     "validations" => {"min" => 0, "max" => 1000000}},
                    {"link_id" => "blood_sugar_checks_transgender",
                     "text" => "Transgender",
                     "type" => "integer",
                     "display" => {"view_type" => "input_field"},
                     "validations" => {"min" => 0, "max" => 1000000}}]}]}
      ]}
    end
  end
end
