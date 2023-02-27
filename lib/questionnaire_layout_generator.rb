class QuestionnaireLayoutGenerator
  def sample_questionnaire_layout
    group(item: [
      sub_header("monthly_screening_reports.monthly_opd_visits_gt_30"),
      input_view_group([
        input("monthly_screening_reports.outpatient_department_visits", "monthly_screening_reports.outpatient_department_visits")
      ]),
      separator,
      header("monthly_screening_reports.htn_and_dm_screening"),
      sub_header("monthly_screening_reports.total_bp_checks"),
      input_view_group([
        input("monthly_screening_reports.male", "monthly_screening_reports.total_bp_checks.male"),
        input("monthly_screening_reports.female", "monthly_screening_reports.total_bp_checks.female")
      ]),
      sub_header("monthly_screening_reports.total_blood_sugar_checks"),
      input_view_group([
        input("monthly_screening_reports.male", "monthly_screening_reports.total_blood_sugar_checks.male"),
        input("monthly_screening_reports.female", "monthly_screening_reports.total_blood_sugar_checks.female")
      ])
    ])
  end

  def group(item: [])
    {type: "group",
     view_type: "view_group",
     item: item}
  end

  def input_view_group(inputs = [])
    {
      type: "group",
      view_type: "input_view_group",
      item: inputs
    }
  end

  def sub_header(text)
    {
      text: text,
      type: "display",
      view_type: "sub_header"
    }
  end

  def header(text)
    {
      text: text,
      type: "display",
      view_type: "header"
    }
  end

  def separator
    {
      type: "display",
      view_type: "separator"
    }
  end

  def line_separator
    {
      type: "display",
      view_type: "line_separator"
    }
  end

  def input(text, link_id, min: 0, max: 100_000)
    {
      link_id: link_id || text,
      text: text,
      type: "integer",
      view_type: "input_field",
      validations: {
        min: min,
        max: max
      }
    }
  end
end
