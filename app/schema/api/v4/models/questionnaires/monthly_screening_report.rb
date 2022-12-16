class Api::V4::Models::Questionnaires::MonthlyScreeningReport
  class << self
    def layout
      {"item" => [
        {"link_id" => "monthly_opd_visits",
         "text" => "monthly_screening_reports.male",
         "type" => "group",
         "display" => {
           "view_type" => "sub_header",
           "orientation" => "vertical"
         },
         "item" => [
           {"link_id" => "outpatient_department_visits",
            "text" => "monthly_screening_reports.male",
            "type" => "integer",
            "validations" => {
              "min" => 0,
              "max" => 1000000
            },
            "display" => {"view_type" => "input_field", "orientation" => "vertical"}}
         ]},
        {"link_id" => "htm_and_dm_screening",
         "text" => "monthly_screening_reports.male",
         "type" => "group",
         "display" => {"view_type" => "header_group", "orientation" => "vertical"},
         "item" =>
            [{"link_id" => "total_bp_checks",
              "text" => "monthly_screening_reports.male",
              "type" => "group",
              "display" => {"view_type" => "sub_header", "orientation" => "horizontal"},
              "item" =>
                 [{"link_id" => "blood_pressure_checks_male",
                   "text" => "monthly_screening_reports.male",
                   "type" => "integer",
                   "validations" => {"min" => 0, "max" => 1000000},
                   "display" => {"view_type" => "input_field"}},
                   {"link_id" => "blood_pressure_checks_female",
                    "text" => "monthly_screening_reports.male",
                    "type" => "integer",
                    "validations" => {"min" => 0, "max" => 1000000},
                    "display" => {"view_type" => "input_field"}}]},
              {"link_id" => "total_blood_sugar_checks",
               "text" => "monthly_screening_reports.male",
               "display" =>
                  {"view_type" => "sub_header_group", "orientation" => "horizontal"},
               "item" =>
                  [{"link_id" => "blood_sugar_checks_male",
                    "text" => "monthly_screening_reports.male",
                    "type" => "integer",
                    "display" => {"view_type" => "input_field"},
                    "validations" => {"min" => 0, "max" => 1000000}},
                    {"link_id" => "blood_sugar_checks_female",
                     "text" => "monthly_screening_reports.male",
                     "type" => "integer",
                     "display" => {"view_type" => "input_field"},
                     "validations" => {"min" => 0, "max" => 1000000}},
                    {"link_id" => "blood_sugar_checks_transgender",
                     "text" => "monthly_screening_reports.male",
                     "type" => "integer",
                     "display" => {"view_type" => "input_field"},
                     "validations" => {"min" => 0, "max" => 1000000}}]}]}
      ]}
    end
  end

  def self.localize_layout_string_sub(layout)
    layout.to_json.to_s
  end

  def self.localize_layout_2(sub_layout)
    case sub_layout
      when Hash
        new_sub_layout = if sub_layout["text"]
          sub_layout.merge({"text" => I18n.t(sub_layout["text"])})
                         else
                           sub_layout
                         end
        new_sub_layout.map do |k, v|
          [k, localize_layout_2(v)]
        end.to_h
      when Array
        sub_layout.map do |abcd|
          localize_layout_2(abcd)
        end
      else
        sub_layout
    end
  end
end



